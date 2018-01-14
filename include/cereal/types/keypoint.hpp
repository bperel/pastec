#include "cereal/cereal.hpp"
#include <memory>
#include <cstring>

#ifndef CEREAL_TYPES_KEYPOINT_HPP__
#define CEREAL_TYPES_KEYPOINT_HPP__

namespace cereal {
    template<class Archive>
    void CEREAL_SAVE_FUNCTION_NAME(Archive & ar, const cv::KeyPoint &keyPoint) {
        float pt_x, pt_y, size, angle, response;
        int octave, class_id;

        pt_x = keyPoint.pt.x;
        pt_y = keyPoint.pt.y;
        size = keyPoint.size;
        angle = keyPoint.angle;
        response = keyPoint.response;
        octave = keyPoint.octave;
        class_id = keyPoint.class_id;

        ar & pt_x & pt_y & size & angle & response & octave & class_id;
    };

    template<class Archive>
    void CEREAL_LOAD_FUNCTION_NAME(Archive &ar, cv::KeyPoint &keyPoint) {
        float pt_x, pt_y, size, angle, response;
        int octave, class_id;

        ar & pt_x & pt_y & size & angle & response & octave & class_id;

        keyPoint.pt = cv::Point2f(pt_x, pt_y);
        keyPoint.size = size;
        keyPoint.angle = angle;
        keyPoint.response = response;
        keyPoint.octave = octave;
        keyPoint.class_id = class_id;
    }
}

#endif // CEREAL_TYPES_KEYPOINT_HPP__
