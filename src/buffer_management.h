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
#ifndef buffer_management_h
#define buffer_management_h

#include <zlib.h>
#include <iostream>
#include <fstream>

#include "logger.h"
#include "cv.h"

using namespace std;
using namespace plog;

bool manage_image(IplImage **image, int width, int height, int depth, int nChannels);
bool load_managed_image(char *filename, IplImage **image, int code);
void free_managed_image(IplImage **image);
void release_managed_image(IplImage **image);

void save_image_in_pakfile(ostream &f, IplImage *image);
bool load_managed_image_in_pakfile(istream &f, IplImage **image);

////////////////////////////////////////////////////////////////////////////////////////////////////////

template<typename T>
void manage_buffer(T * & buffer, size_t required_size) {
    buffer = (T *)new char[required_size * sizeof(T)];
}

template<typename T>
void delete_managed_buffer(T * & buffer) {
    delete[] buffer;
    buffer = nullptr;
}

extern Bytef *__managed_compressed_buffer;

template<typename T>
void save_buffer_in_pakfile(ostream & f, T * buffer, size_t size) {
    if (size < (1L << 10)) {
        f << "0 " << size << endl;
        char dot('.');
        f.write(&dot, 1);
        f.write((char *) buffer, size * sizeof(T));
    } else {
        log_debug << "[buffer_management::save_buffer_in_pakfile]"
                  << "Writing compressed buffer..." << endl;
        int max_required_size = size * sizeof(T);
        manage_buffer(__managed_compressed_buffer, max_required_size);
        uLongf size_of_compressed_buffer = max_required_size;
        int z_error = compress(
                __managed_compressed_buffer, &size_of_compressed_buffer,
                (Bytef *) buffer, max_required_size);
        if (z_error != Z_OK)
            log_debug << "[buffer_management::save_buffer_in_pakfile]"
                      << "zlib error = " << z_error << ")" << endl;
        log_debug << "[buffer_management::save_buffer_in_pakfile]"
                  << " Compression ratio = "
                  << float(max_required_size) / size_of_compressed_buffer << "." << endl;
        f << "1 " << size_of_compressed_buffer << " " << size << endl;
        char dot('.');
        f.write(&dot, 1);
        f.write((char *) __managed_compressed_buffer, size_of_compressed_buffer);
        delete_managed_buffer(__managed_compressed_buffer);
    }
}

template<typename T>
void load_managed_buffer_in_pakfile(istream & f, T * & buffer, size_t size) {
    bool compressed = false;
    f >> compressed;
    if (!compressed) {
        f >> size;
        manage_buffer(buffer, size);
        f.read((char *) buffer, size * sizeof(T));
    } else {
        log_debug << "[buffer_management::load_managed_buffer_in_pakfile]"
                  << "Reading compressed buffer..." << endl;
        int size_of_compressed_buffer;
        f >> size_of_compressed_buffer >> size;
        char c;
        do f.read(&c, 1); while (c != '.');
        manage_buffer(__managed_compressed_buffer, size_of_compressed_buffer);
        f.read((char *) __managed_compressed_buffer, size_of_compressed_buffer);
        uLongf uncompressed_buffer_size = size * sizeof(T);
        manage_buffer(buffer, size);
        int z_error = uncompress(
                (Bytef *) buffer, &uncompressed_buffer_size,
                __managed_compressed_buffer, size_of_compressed_buffer);
        delete_managed_buffer(__managed_compressed_buffer);
        if (z_error != Z_OK)
            log_debug << "[buffer_management::load_managed_buffer_in_pakfile]"
                      << "zlib error = " << z_error << ")" << endl;
    }
}

#endif //buffer_management_h
