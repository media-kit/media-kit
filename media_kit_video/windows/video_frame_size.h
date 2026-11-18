// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// Use of this source code is governed by the MIT license in the LICENSE file.

#ifndef MEDIA_KIT_VIDEO_FRAME_SIZE_H_
#define MEDIA_KIT_VIDEO_FRAME_SIZE_H_

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <optional>

namespace media_kit {

constexpr int32_t kSoftwareMaxWidth = 1920;
constexpr int32_t kSoftwareMaxHeight = 1080;
constexpr size_t kSoftwareBufferCapacity =
    size_t{kSoftwareMaxWidth} * kSoftwareMaxHeight * 4;

struct VideoFrameSize {
  int32_t width;
  int32_t height;
};

// Overrides apply independently, as in the native configuration contract:
// a missing side uses that side of the rotated video, not an inferred ratio.
// The software limit then scales the resulting pair uniformly, rounding down
// (with a one-pixel minimum). Small frames are never enlarged.
inline std::optional<VideoFrameSize> ResolveVideoFrameSize(
    int64_t display_width,
    int64_t display_height,
    int64_t rotation,
    std::optional<int64_t> width,
    std::optional<int64_t> height,
    bool software) {
  const auto normalized_rotation = (rotation % 360 + 360) % 360;
  if (normalized_rotation == 90 || normalized_rotation == 270) {
    std::swap(display_width, display_height);
  }
  int64_t w = width.value_or(display_width);
  int64_t h = height.value_or(display_height);
  const auto max_dimension = (std::numeric_limits<int32_t>::max)();
  if (w < 1 || h < 1 || w > max_dimension || h > max_dimension) {
    return std::nullopt;
  }
  if (software && (w > kSoftwareMaxWidth || h > kSoftwareMaxHeight)) {
    // Products fit in int64_t after the range check above. Integer arithmetic
    // avoids floating-point rounding past the buffer's width/height limits.
    if (w * kSoftwareMaxHeight >= h * kSoftwareMaxWidth) {
      h = (std::max)(int64_t{1}, h * kSoftwareMaxWidth / w);
      w = kSoftwareMaxWidth;
    } else {
      w = (std::max)(int64_t{1}, w * kSoftwareMaxHeight / h);
      h = kSoftwareMaxHeight;
    }
  }
  return VideoFrameSize{static_cast<int32_t>(w), static_cast<int32_t>(h)};
}

struct SoftwareFrameLayout {
  size_t stride;
  size_t bytes;
};

inline std::optional<SoftwareFrameLayout> GetSoftwareFrameLayout(
    VideoFrameSize size,
    size_t capacity) {
  if (size.width < 1 || size.height < 1)
    return std::nullopt;
  const size_t width = static_cast<size_t>(size.width);
  const size_t height = static_cast<size_t>(size.height);
  const size_t maximum = (std::numeric_limits<size_t>::max)();
  if (width > maximum / 4)
    return std::nullopt;
  const size_t stride = width * 4;
  if (height > maximum / stride)
    return std::nullopt;
  const size_t bytes = stride * height;
  if (bytes > capacity)
    return std::nullopt;
  // FlutterDesktopPixelBuffer has no stride field: rows must be tightly packed.
  return SoftwareFrameLayout{stride, bytes};
}

}  // namespace media_kit

#endif  // MEDIA_KIT_VIDEO_FRAME_SIZE_H_
