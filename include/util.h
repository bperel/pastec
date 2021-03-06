/*****************************************************************************
 * Copyright (C) 2014 Visualink
 *
 * Authors: Adrien Maglo <adrien@visualink.io>
 *
 * This file is part of Pastec.
 *
 * Pastec is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Pastec is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Pastec.  If not, see <http://www.gnu.org/licenses/>.
 *****************************************************************************/

#ifndef PASTEC_UTIL_H
#define PASTEC_UTIL_H

#include <string>
#include <string.h>
#include <iostream>

inline std::string currentDate()
{
    time_t _tm = time(NULL );
    struct tm * curtime = localtime ( &_tm );
    char* currenttime = asctime(curtime);
    currenttime[strlen(currenttime) - 1] = 0;

    std::string currenttime_str(currenttime);
    return "[" + currenttime_str + "] ";
}

#endif // PASTEC_UTIL_H
