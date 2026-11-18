#include "../video_frame_size.h"

#include <cstdlib>
#include <iostream>
#include <type_traits>

namespace {
int checks = 0;
void Check(bool condition, const char* description) {
  ++checks;
  if (!condition) {
    std::cerr << "FAIL: " << description << std::endl;
    std::exit(1);
  }
}
void Size(int64_t w,
          int64_t h,
          int64_t rotation,
          int32_t expected_w,
          int32_t expected_h,
          std::optional<int64_t> fixed_w = std::nullopt,
          std::optional<int64_t> fixed_h = std::nullopt,
          bool software = true) {
  const auto size = media_kit::ResolveVideoFrameSize(w, h, rotation, fixed_w,
                                                     fixed_h, software);
  Check(size && size->width == expected_w && size->height == expected_h,
        "resolved dimensions");
  if (software) {
    Check(media_kit::GetSoftwareFrameLayout(*size,
                                            media_kit::kSoftwareBufferCapacity)
              .has_value(),
          "resolved software frame fits allocation");
  }
}
}  // namespace

int main() {
  using namespace media_kit;
  static_assert(std::is_same_v<decltype(SoftwareFrameLayout::stride), size_t>);
  Size(3840, 1600, 0, 1920, 800);
  Size(3840, 2160, 0, 1920, 1080);
  Size(1080, 1920, 0, 607, 1080);
  Size(1920, 1080, 90, 607, 1080);
  Size(1920, 1080, 270, 607, 1080);
  Size(1920, 1080, -90, 607, 1080);
  Size(1920, 1080, 180, 1920, 1080);
  Size(641, 359, 0, 641, 359);
  Size(1, 1, 0, 1, 1);
  Size(1, INT32_MAX, 0, 1, 1080);
  Size(INT32_MAX, 1, 0, 1920, 1);
  Size(INT32_MAX, INT32_MAX, 0, 1080, 1080);
  // Initial explicit sizes, including a configuration before any video exists.
  Size(0, 0, 0, 1920, 800, 3840, 1600);
  Size(1920, 1080, 0, 640, 360, 640, 360);
  Size(1920, 1080, 0, 640, 1080, 640);
  Size(1920, 1080, 0, 1920, 360, std::nullopt, 360);
  Size(3840, 1600, 0, 3840, 1600, std::nullopt, std::nullopt, false);
  for (const auto value :
       {int64_t{0}, int64_t{-1}, int64_t{INT32_MAX} + 1, INT64_MAX}) {
    Check(!ResolveVideoFrameSize(value, 1080, 0, {}, {}, true),
          "invalid width");
    Check(!ResolveVideoFrameSize(1920, value, 0, {}, {}, true),
          "invalid height");
    Check(!ResolveVideoFrameSize(1920, 1080, 0, value, {}, true),
          "invalid override");
  }
  const auto odd = GetSoftwareFrameLayout({641, 359}, 641 * 359 * 4);
  Check(odd && odd->stride == 2564 && odd->bytes == 920476, "packed odd width");
  Check(!GetSoftwareFrameLayout({641, 359}, 920475), "short buffer rejected");
  Check(!GetSoftwareFrameLayout({0, 1080}, kSoftwareBufferCapacity),
        "zero width");
  Check(!GetSoftwareFrameLayout({1920, -1}, kSoftwareBufferCapacity),
        "negative height");
  Check(
      !GetSoftwareFrameLayout({INT32_MAX, INT32_MAX}, kSoftwareBufferCapacity),
      "oversized buffer rejected");
  const auto full =
      GetSoftwareFrameLayout({1920, 1080}, kSoftwareBufferCapacity);
  Check(full && full->bytes == kSoftwareBufferCapacity, "exact capacity");
  std::cout << "PASS: " << checks << " frame size/layout checks" << std::endl;
}
