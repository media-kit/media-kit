// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.

#ifndef MEDIA_KIT_VIDEO_WINDOWS_ANGLE_SURFACE_MANAGER_H_
#define MEDIA_KIT_VIDEO_WINDOWS_ANGLE_SURFACE_MANAGER_H_

// Make declarations in |d3d9.h| visible.
#define DIRECT3D_VERSION 0x0900

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglplatform.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include <Windows.h>

#include <d3d.h>
#include <d3d11.h>
#include <d3d9.h>
#include <wrl.h>

#include <cstdint>

class ANGLESurfaceManager {
 public:
  const int32_t width() const { return width_; }
  const int32_t height() const { return height_; }
  const HANDLE handle() const { return handle_; }

  // Creates a new instance of |ANGLESurfaceManager|, automatically creates
  // internal D3D 11 & D3D 9 devices based on platform's capability.
  ANGLESurfaceManager(int32_t width, int32_t height);

  ~ANGLESurfaceManager();

  // Resizes the internal |ID3D11Texture2D| & |EGLSurface| and returns updated
  // |handle_|. This preserves the |context_| & |display_| associated
  // with this |ANGLESurfaceManager| instance.
  HANDLE HandleResize(int32_t width, int32_t height);

  void SwapBuffers();

  void MakeCurrent(bool value);

 private:
  bool CreateEGLDisplay();

  // Creates new Direct3D device & texture, EGL |display_|, |context_| &
  // |surface_| using |width_| & |height_|. If a |display_| & |context_| already
  // exists, then it is preserved. Only new Direct3D device & texture &
  // |surface_| will be created if |height_| & |width_| were changed e.g. by
  // |HandleResize|.
  void Initialize();

  // Attempts to create D3D 11 (and compatibility supported) device & texture.
  // Returns success as bool.
  bool InitializeD3D11();

  // Attempts to create D3D 9 (and compatibility supported) device & texture.
  // Returns success as bool.
  // NOTE: Not working.
  bool InitializeD3D9();

  void CleanUp(bool release_context);

  // Creates ANGLE specific |surface_| and |context_| after consuming D3D
  // |handle_| from either |InitializeD3D11| or |InitializeD3D9|.
  bool CreateAndBindEGLSurface();

  IDXGIAdapter* adapter_ = nullptr;
  int32_t width_ = 1;
  int32_t height_ = 1;
  // D3D 11 specific references.
  ID3D11Device* d3d_11_device_ = nullptr;
  ID3D11DeviceContext* d3d_11_device_context_ = nullptr;
  Microsoft::WRL::ComPtr<ID3D11Texture2D> d3d11_texture_2D_;
  Microsoft::WRL::ComPtr<IDXGISwapChain> d3d11_swap_chain_;
  // D3D 9 specific references.
  IDirect3D9Ex* d3d_9_ex_ = nullptr;
  IDirect3DDevice9Ex* d3d_9_device_ex_ = nullptr;
  IDirect3DTexture9* d3d_9_texture_ = nullptr;
  // ANGLE specific references.
  HANDLE handle_ = nullptr;
  EGLSurface surface_ = EGL_NO_SURFACE;
  EGLDisplay display_ = EGL_NO_DISPLAY;
  EGLContext context_ = nullptr;
  EGLConfig config_ = nullptr;

  static constexpr EGLint kEGLConfigurationAttributes[] = {
      EGL_RED_SIZE,   8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE,    8,
      EGL_ALPHA_SIZE, 8, EGL_DEPTH_SIZE, 8, EGL_STENCIL_SIZE, 8,
      EGL_NONE,
  };
  static constexpr EGLint kEGLContextAttributes[] = {
      EGL_CONTEXT_CLIENT_VERSION,
      2,
      EGL_NONE,
  };
  static constexpr EGLint kD3D11DisplayAttributes[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE,
      EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE,
      EGL_TRUE,
      EGL_NONE,
  };
  static constexpr EGLint kD3D11_9_3DisplayAttributes[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE,
      EGL_PLATFORM_ANGLE_MAX_VERSION_MAJOR_ANGLE,
      9,
      EGL_PLATFORM_ANGLE_MAX_VERSION_MINOR_ANGLE,
      3,
      EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE,
      EGL_TRUE,
      EGL_NONE,
  };
  static constexpr EGLint kD3D9DisplayAttributes[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D9_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_DEVICE_TYPE_HARDWARE_ANGLE,
      EGL_NONE,
  };
  static constexpr EGLint kWrapDisplayAttributes[] = {
      EGL_PLATFORM_ANGLE_TYPE_ANGLE,
      EGL_PLATFORM_ANGLE_TYPE_D3D11_ANGLE,
      EGL_PLATFORM_ANGLE_ENABLE_AUTOMATIC_TRIM_ANGLE,
      EGL_TRUE,
      EGL_NONE,
  };
};

#endif  // MEDIA_KIT_VIDEO_WINDOWS_ANGLE_SURFACE_MANAGER_H_
