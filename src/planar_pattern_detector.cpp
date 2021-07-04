/*
  Copyright 2007 Computer Vision Lab,
  Ecole Polytechnique Federale de Lausanne (EPFL), Switzerland.
  All rights reserved.

  Author: Vincent Lepetit (http://cvlab.epfl.ch/~lepetit)

  This file is part of the ferns_demo software.

  ferns_demo is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2 of the License, or (at your option) any later
  version.

  ferns_demo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
  PARTICULAR PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along with
  ferns_demo; if not, write to the Free Software Foundation, Inc., 51 Franklin
  Street, Fifth Floor, Boston, MA 02110-1301, USA
*/
#include <algorithm>
#include <fstream>

#include "logger.h"
#include "mcv.h"
#include "planar_pattern_detector.h"
#include "buffer_management.h"

using namespace std;
using namespace plog;

planar_pattern_detector::planar_pattern_detector(void)
{
  model_image = nullptr;
  pyramid = nullptr;
  model_points = detected_points = nullptr;
  maximum_number_of_points_to_detect = 500;

  classifier = new fern_based_point_classifier(0, 0, 0, 0, 0, 0, 0, 0, 0);
  image_generator = new affine_image_generator06();
  point_detector = new pyr_yape06();
  H_estimator = new homography_estimator;
}

planar_pattern_detector::~planar_pattern_detector(void)
{
  if (model_image) cvReleaseImage(&model_image);
  if (pyramid) delete pyramid;
  if (classifier) delete classifier;

  if (image_generator) delete image_generator;
  if (point_detector) delete point_detector;

  if (model_points) delete [] model_points;
  if (detected_points) delete_managed_buffer(detected_points);

  if (H_estimator) delete H_estimator;
}

bool planar_pattern_detector::load(const char * filename)
{
  ifstream f(filename, ios::binary);

  if (!f.is_open()) return false;

  log_info << "[planar_pattern_detector::load]" << "Loading detector file " << filename << " ... " << endl;

  bool result = load(f);

  f.close();

  log_verb << "[planar_pattern_detector::load]" << "Ok." << endl;

  return result;
}

bool planar_pattern_detector::save(const char * filename)
{
  ofstream f(filename, ios::binary);

  if (!f.is_open()) {
    log_error << "[planar_pattern_detector::save]" << "Error saving file " << filename << "." << endl;
    return false;
  }

  log_info << "[planar_pattern_detector::save]" << "Saving detector file " << filename << " ... " << endl;

  bool result = save(f);

  f.close();

  log_verb << "[planar_pattern_detector::save]" << "Ok." << endl;

  return result;
}

bool planar_pattern_detector::load(istream & f)
{
  f >> image_name;

  log_debug << "[planar_pattern_detector::load]" << "Image name: " << image_name << endl;

  for(int i = 0; i < 4; i++) f >> u_corner[i] >> v_corner[i];

  f >> patch_size >> yape_radius >> number_of_octaves;
  log_verb << "[planar_pattern_detector::load]"
           << "Patch size = " << patch_size
           << ", Yape radius = " << yape_radius
           << ", Number of octaves = " << number_of_octaves
           << "." << endl;

  pyramid = new fine_gaussian_pyramid(yape_radius, patch_size, number_of_octaves);

  image_generator->load_transformation_range(f);
  
  f >> mean_recognition_rate;
  log_verb << "[planar_pattern_detector::load]" << "Recognition rate: " << mean_recognition_rate << endl;

  load_managed_image_in_pakfile(f, &model_image);

  f >> number_of_model_points;
  log_verb << "[planar_pattern_detector::load]" << number_of_model_points << " model points." << endl;

  model_points = new keypoint[number_of_model_points];
  for(int i = 0; i < number_of_model_points; i++) {
    f >> model_points[i].u >> model_points[i].v >> model_points[i].scale;
    model_points[i].class_index = i;
  }

  image_generator->set_original_image(model_image);
  image_generator->set_mask(u_corner[0], v_corner[0], u_corner[2], v_corner[2]);

  classifier = new fern_based_point_classifier(f);

  return true;
}

bool planar_pattern_detector::save(ostream & f)
{
  f << image_name << endl;

  for(int i = 0; i < 4; i++) f << u_corner[i] << " " << v_corner[i] << endl;

  f << patch_size << " " << yape_radius << " " << number_of_octaves << endl;

  image_generator->save_transformation_range(f);

  f << mean_recognition_rate << endl;

  save_image_in_pakfile(f, model_image);

  f << number_of_model_points << endl;
  for(int i = 0; i < number_of_model_points; i++)
    f << model_points[i].u << " " << model_points[i].v << " " << model_points[i].scale << endl;

  classifier->save(f);

  return true;
}

//! Set the maximum number of points we want to detect
void planar_pattern_detector::set_maximum_number_of_points_to_detect(int max)
{
  maximum_number_of_points_to_detect = max;
}

bool planar_pattern_detector::detect(const IplImage * input_image)
{
  if (input_image->nChannels != 1 || input_image->depth != IPL_DEPTH_8U) {
    log_error << "[planar_pattern_detector::detect]"
              << "Wrong image format "
              << "nChannels = " << input_image->nChannels
              << ", depth = " << input_image->depth << "." << endl;

    return false;
  }

  pyramid->set_image(input_image);
  detect_points(pyramid);
  return detect(pyramid);
}

bool planar_pattern_detector::detect(fine_gaussian_pyramid * pyramid)
{
  match_points(pyramid);

  pattern_is_detected = estimate_H();

  if (pattern_is_detected) {
    for(int i = 0; i < 4; i++)
      H.transform_point(u_corner[i], v_corner[i], detected_u_corner[i], detected_v_corner[i]);

    number_of_matches = 0;
    for(int i = 0; i < number_of_model_points; i++)
      if (model_points[i].class_score > 0) {
        float Hu, Hv;
        H.transform_point(model_points[i].fr_u(), model_points[i].fr_v(), Hu, Hv);
        float dist2 =
          (Hu - model_points[i].potential_correspondent->fr_u()) *
          (Hu - model_points[i].potential_correspondent->fr_u()) +
          (Hv - model_points[i].potential_correspondent->fr_v()) *
          (Hv - model_points[i].potential_correspondent->fr_v());
        if (dist2 > 10.0 * 10.0)
          model_points[i].class_score = 0.0;
        else
          number_of_matches++;
      }
  }

  return pattern_is_detected;
}

void planar_pattern_detector::save_image_of_model_points(const char * filename, int patch_size)
{
  IplImage * color_model_image = mcvGrayToColor(model_image);

  for(int i = 0; i < number_of_model_points; i++)
    mcvCircle(color_model_image,
              int( model_points[i].fr_u() + 0.5 ), int( model_points[i].fr_v() + 0.5 ), patch_size / 2 * (1 << int(model_points[i].scale)),
              cvScalar(0, 255, 0), 2);

  mcvSaveImage(filename, color_model_image);
  cvReleaseImage(&color_model_image);
}

void planar_pattern_detector::detect_points(fine_gaussian_pyramid * pyramid)
{
  manage_buffer(detected_points, maximum_number_of_points_to_detect);
  //   point_detector->set_laplacian_threshold(10);
  //   point_detector->set_min_eigenvalue_threshold(10);
  number_of_detected_points = point_detector->detect(pyramid, detected_points, maximum_number_of_points_to_detect);
}

void planar_pattern_detector::match_points(fine_gaussian_pyramid * pyramid)
{
  for(int i = 0; i < number_of_model_points; i++) {
    model_points[i].potential_correspondent = 0;
    model_points[i].class_score = 0;
  }

  for(int i = 0; i < number_of_detected_points; i++) {
    keypoint * k = detected_points + i;

    classifier->recognize(pyramid, k);

    if (k->class_index >= 0) {
      float true_score = exp(k->class_score);

      if (model_points[k->class_index].class_score < true_score) {
        model_points[k->class_index].potential_correspondent = k;
        model_points[k->class_index].class_score = true_score;
      }
    }
  }
}

bool planar_pattern_detector::estimate_H(void)
{
  H_estimator->reset_correspondences(number_of_model_points);

  for(int i = 0; i < number_of_model_points; i++)
    if (model_points[i].class_score > 0)
      H_estimator->add_correspondence(model_points[i].fr_u(), model_points[i].fr_v(),
                                      model_points[i].potential_correspondent->fr_u(), model_points[i].potential_correspondent->fr_v(),
                                      model_points[i].class_score);

  return H_estimator->ransac(&H, 10.0, 1500, 0.99, true) > 10;
}

//! test()
void planar_pattern_detector::test(int number_of_samples_for_test)
{
  float rate = classifier->test(model_points, number_of_model_points,
                                number_of_octaves, yape_radius, number_of_samples_for_test,
                                image_generator);

  log_info << "[planar_pattern_detector::test]" << "Rate: " << rate << endl;
}

// For debug purposes:

#if pyr_debug
IplImage * planar_pattern_detector::create_image_of_matches(void)
{
  int width = MAX(model_image->width, pyramid->original_image->width);
  int height = model_image->height + pyramid->original_image->height;
  IplImage * result = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 3);

  mcvPut(result, model_image, 0, 0);
  mcvPut(result, pyramid->original_image, 0, model_image->height);

  int h = model_image->height;

  for(int i = 0; i < number_of_model_points; i++)
    mcvCross(result, model_points[i].fr_u(), model_points[i].fr_v(), 5, cvScalar(255, 0, 0), 1);

  log_info << "[planar_pattern_detector::create_image_of_matches]"
           << number_of_detected_points << " detected points." << endl;

  for(int i = 0; i < number_of_detected_points; i++)
    mcvCross(result, detected_points[i].fr_u(), h + detected_points[i].fr_v(), 5, cvScalar(255, 0, 0), 1);

  if (!pattern_is_detected) return result;
  
  CvScalar color = cvScalar(0,255,0);
  cvLine(result,
         cvPoint(detected_u_corner[0], h + detected_v_corner[0]),
         cvPoint(detected_u_corner[1], h + detected_v_corner[1]),
         color, 3);

  cvLine(result,
         cvPoint(detected_u_corner[1], h + detected_v_corner[1]),
         cvPoint(detected_u_corner[2], h + detected_v_corner[2]),
         color, 3);

  cvLine(result,
         cvPoint(detected_u_corner[2], h + detected_v_corner[2]),
         cvPoint(detected_u_corner[3], h + detected_v_corner[3]),
         color, 3);

  cvLine(result,
         cvPoint(detected_u_corner[3], h + detected_v_corner[3]),
         cvPoint(detected_u_corner[0], h + detected_v_corner[0]),
         color, 3);

  number_of_matches = 0;
  for(int i = 0; i < number_of_model_points; i++)
    if (model_points[i].class_score > 0) {
      number_of_matches++;
      cvLine(result,
             cvPoint(model_points[i].fr_u(), model_points[i].fr_v()),
             cvPoint(model_points[i].potential_correspondent->fr_u(),
                     h + model_points[i].potential_correspondent->fr_v()),
             color, 1);
      cvCircle(result,
               cvPoint(model_points[i].potential_correspondent->fr_u(),
                       h + model_points[i].potential_correspondent->fr_v()),
               16 * (1 << int(model_points[i].potential_correspondent->scale)),
               color, 1);
    }

  log_info << "[planar_pattern_detector::create_image_of_matches]"
           << "Number of matches: " << number_of_matches << endl;
  return result;
}
#endif
