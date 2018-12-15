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

#include <iostream>
#include <set>
#include <unordered_set>

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/features2d/features2d.hpp>

#include <orbfeatureextractor.h>
#include <messages.h>
#include <imageloader.h>

#include <cereal/types/keypoint.hpp>
#include <cereal/types/mat.hpp>
#include <cereal/types/vector.hpp>
#include <cereal/archives/json.hpp>
#include <cereal/archives/binary.hpp>


ORBFeatureExtractor::ORBFeatureExtractor(ORBIndex *index, ORBWordIndex *wordIndex)
    : index(index), wordIndex(wordIndex), orb(ORB::create(2000, 1.02, 100))
{ }

ORBProcess * ORBFeatureExtractor::processImage(unsigned i_imgSize, char *p_imgData)
{
    auto *currentImageProcess = new ORBProcess;

    Mat img;
    currentImageProcess->resultStatus = ImageLoader::loadImage(i_imgSize, p_imgData, img);
    if (currentImageProcess->resultStatus == OK) {
        //equalizeHist( img, img );

        orb->detectAndCompute(img, noArray(), currentImageProcess->keypoints, currentImageProcess->descriptors);
    }

    return currentImageProcess;
}

ORBProcess * ORBFeatureExtractor::processNewImage(unsigned i_imageId, unsigned i_imgSize, char *p_imgData)
{
    ORBProcess *currentImageProcess = processImage(i_imgSize, p_imgData);

    list<HitForward> imageHits;
    processKeyPointsAndDescriptors(i_imageId, currentImageProcess->keypoints, currentImageProcess->descriptors, imageHits);

#if 0
    // Draw keypoints.
    Mat img_res;
    drawKeypoints(img, keypoints, img_res, Scalar::all(-1), DrawMatchesFlags::DEFAULT);

    // Show the image.
    imshow("Keypoints 1", img_res);
    waitKey();
#endif

    // Record the hits.
    currentImageProcess->resultStatus = index->addImage(i_imageId, imageHits);

    return currentImageProcess;
}

u_int32_t ORBFeatureExtractor::processKeyPointsAndDescriptors(u_int32_t i_imageId, const vector<KeyPoint> keypoints,
                                                              const Mat &descriptors, list<HitForward> &imageHits)
{
    unordered_set<u_int32_t> matchedWords;
    for (unsigned i = 0; i < keypoints.size(); ++i)
    {
        auto keypoint = keypoints[i];

        // Recording the angle on 16 bits.
        auto angle = static_cast<u_int16_t>(keypoint.angle / 360 * (1 << 16));
        auto x = static_cast<u_int16_t>(keypoint.pt.x);
        auto y = static_cast<u_int16_t>(keypoint.pt.y);

        vector<int> indices(1);
        vector<int> dists(1);
        wordIndex->knnSearch(descriptors.row(i), indices, dists, 1);

        for (unsigned int i_wordId : indices) {
            if (matchedWords.find(i_wordId) == matchedWords.end())
            {
                HitForward newHit{};
                newHit.i_wordId = i_wordId;
                newHit.i_imageId = i_imageId;
                newHit.i_angle = angle;
                newHit.x = x;
                newHit.y = y;
                imageHits.push_back(newHit);
                matchedWords.insert(i_wordId);
            }
        }
    }

#if 0
    // Draw keypoints.
    Mat img_res;
    drawKeypoints(img, keypoints, img_res, Scalar::all(-1), DrawMatchesFlags::DEFAULT);

    // Show the image.
    imshow("Keypoints 1", img_res);
    waitKey();
#endif

    // Record the hits.
    return index->addImage(i_imageId, imageHits);
}
