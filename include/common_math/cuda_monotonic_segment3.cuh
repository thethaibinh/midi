/*!
 * Copyright 2024 by Binh Nguyen <thethaibinh@gmail.com>
 *
 * This code is free software: you can redistribute
 * it and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * This code is distributed in the hope that it will
 * be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the code.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "common_math/cuda_segment3.cuh"

namespace common_math {
class CudaMonotonicSegment3 : public CudaThirdOrderSegment {
 public:
  //! Creates a trajectory with monotonically changing depth (i.e. position
  //! along the z-axis). Note that we do not check if the given trajectory
  //! actually has monotonically z-position between the start and end times; we
  //! assume this is the case.
  /*!
   * @param coeffs The parameters defining the trajectory
   * @param startTime Endpoint of the trajectory [seconds]
   * @param endTime Endpoint of the trajectory [seconds]
   */
  __device__ __host__ CudaMonotonicSegment3(const CudaVector3d* coeffs,
                                            const double& startTime,
                                            const double& endTime)
    : CudaThirdOrderSegment(coeffs, startTime, endTime) {
    double startVal = CudaThirdOrderSegment::get_axis_value(2, startTime);
    double endVal = CudaThirdOrderSegment::get_axis_value(2, endTime);
    increasing_depth = startVal < endVal;  // index 2 = z-value
  }

  //! We include this operator so that we can sort the monotonic sections based
  //! on the depth of their deepest point. The idea is that we should check the
  //! monotonic section with the deepest depth for collisions first, as it's the
  //! most likely to collide with the environment.
  bool operator<(const CudaMonotonicSegment3& rhs) const {
    double deepestDepth, rhsDeepestDepth;
    if (increasing_depth) {
      deepestDepth = CudaThirdOrderSegment::get_axis_value(
        2, CudaThirdOrderSegment::get_end_time());
    } else {
      deepestDepth = CudaThirdOrderSegment::get_axis_value(
        2, CudaThirdOrderSegment::get_start_time());
    }
    if (rhs.increasing_depth) {
      rhsDeepestDepth = rhs.get_axis_value(2, rhs.get_end_time());
    } else {
      rhsDeepestDepth = rhs.get_axis_value(2, rhs.get_start_time());
    }
    return deepestDepth < rhsDeepestDepth;
  }

  bool is_increasing_depth() const { return increasing_depth; }

 private:
  //! True if the position of the trajectory along the z-axis monotonically
  //! increases in time
  bool increasing_depth;
};

}  // namespace common_math