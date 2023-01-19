// This file is a part of media_kit
// (https://github.com/alexmercerind/media_kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#include "angle_surface_manager.h"

#include <iostream>

#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3d9.lib")
#pragma comment(lib, "d3d11.lib")

#define FAIL(message)                                                 \
  std::cout << "media_kit: ANGLESurfaceManager: Failure: " << message \
            << std::endl;                                             \
  return false

#define CHECK_HRESULT(message) \
  if (FAILED(hr)) {            \
    FAIL(message);             \
  }

ANGLESurfaceManager::ANGLESurfaceManager(int32_t width, int32_t height)
    : width_(width), height_(height) {
  // Create new Direct3D texture & |surface_|, |display_| & |context_|.
  Initialize();
  MakeCurrent(true);
}

ANGLESurfaceManager::~ANGLESurfaceManager() {
  CleanUp(true);
}

HANDLE ANGLESurfaceManager::HandleResize(int32_t width, int32_t height) {
  if (width == width_ && height == height_) {
    // Same dimensions.
    return handle_;
  }
  width_ = width;
  height_ = height;
  // Create new Direct3D texture & |surface_| preserving previously created
  // |display_| & |context_| from the constructor.
  Initialize();
  return handle_;
}

void ANGLESurfaceManager::SwapBuffers() {
#ifdef ENABLE_GL_FINISH_SAFEGUARD
  glFinish();
#endif
}

void ANGLESurfaceManager::MakeCurrent(bool value) {
  if (value) {
#ifdef ENABLE_GL_FINISH_SAFEGUARD
    glFinish();
#endif
    eglMakeCurrent(display_, surface_, surface_, context_);
  } else {
#ifdef ENABLE_GL_FINISH_SAFEGUARD
    glFinish();
#endif
    eglMakeCurrent(EGL_NO_DISPLAY, EGL_NO_SURFACE, EGL_NO_SURFACE,
                   EGL_NO_CONTEXT);
  }
}

bool ANGLESurfaceManager::CreateEGLDisplay() {
  if (display_ == EGL_NO_DISPLAY) {
    auto eglGetPlatformDisplayEXT =
        reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(
            eglGetProcAddress("eglGetPlatformDisplayEXT"));
    if (eglGetPlatformDisplayEXT) {
      // D3D11.
      display_ = eglGetPlatformDisplayEXT(EGL_PLATFORM_ANGLE_ANGLE,
                                          EGL_DEFAULT_DISPLAY,
                                          kD3D11DisplayAttributes);
      if (eglInitialize(display_, 0, 0) == EGL_FALSE) {
        // D3D 11 Feature Level 9_3.
        display_ = eglGetPlatformDisplayEXT(EGL_PLATFORM_ANGLE_ANGLE,
                                            EGL_DEFAULT_DISPLAY,
                                            kD3D11_9_3DisplayAttributes);
        if (eglInitialize(display_, 0, 0) == EGL_FALSE) {
          // D3D 9.
          display_ = eglGetPlatformDisplayEXT(EGL_PLATFORM_ANGLE_ANGLE,
                                              EGL_DEFAULT_DISPLAY,
                                              kD3D9DisplayAttributes);
          if (eglInitialize(display_, 0, 0) == EGL_FALSE) {
            // Whatever.
            display_ = eglGetPlatformDisplayEXT(EGL_PLATFORM_ANGLE_ANGLE,
                                                EGL_DEFAULT_DISPLAY,
                                                kWrapDisplayAttributes);
            if (eglInitialize(display_, 0, 0) == EGL_FALSE) {
              FAIL("eglGetPlatformDisplayEXT");
            }
          }
        }
      }
    } else {
      FAIL("eglGetProcAddress");
    }
  }
  return true;
}

void ANGLESurfaceManager::Initialize() {
  // Release previously allocated resources. Do not release existing |context_|,
  // if any.
  CleanUp(false);

  // Presently, I believe it is a good idea to show these failure messages
  // directly to the user. It'll help fix the platform & hardware specific
  // issues.

  // Create new D3D device & texture.
  auto success = InitializeD3D11();
  // TODO: ANGLE's Direct X interop doesn't seem to work with anything below
  // DirectX 11 or even WDDM 1.0 + Direct9Ex. Flutter also seems to fallback to
  // software rendering. I have tested Windows 7 in a VirtualBox & there doesn't
  // seem to be any hardware accelerated rendering inside Flutter window.
  if (!success) {
    throw std::runtime_error("Unable to create Windows Direct3D device.");
    return;
  }
  // Create & bind ANGLE EGL surface.
  success = CreateAndBindEGLSurface();
  // Exit on error.
  if (!success) {
    throw std::runtime_error("Unable to create ANGLE EGL surface.");
    return;
  }
  // Additional check.
  if (handle_ == nullptr) {
    throw std::runtime_error("Unable to retrieve Direct3D shared HANDLE.");
    return;
  }
}

bool ANGLESurfaceManager::InitializeD3D11() {
  if (adapter_ == nullptr) {
#ifdef ENABLE_ID3D11DEVICE_FROM_ANGLE
    // Query |adapter_| from ANGLE directly.
    PFNEGLQUERYDISPLAYATTRIBEXTPROC eglQueryDisplayAttribEXT =
        reinterpret_cast<PFNEGLQUERYDISPLAYATTRIBEXTPROC>(
            eglGetProcAddress("eglQueryDisplayAttribEXT"));
    PFNEGLQUERYDEVICEATTRIBEXTPROC eglQueryDeviceAttribEXT =
        reinterpret_cast<PFNEGLQUERYDEVICEATTRIBEXTPROC>(
            eglGetProcAddress("eglQueryDeviceAttribEXT"));
    if (!eglQueryDisplayAttribEXT || !eglQueryDeviceAttribEXT) {
      FAIL("eglGetProcAddress");
    }
    CreateEGLDisplay();
    EGLAttrib egl_device = 0, angle_device = 0;
    if (eglQueryDisplayAttribEXT(display_, EGL_DEVICE_EXT, &egl_device) ==
        EGL_TRUE) {
      if (eglQueryDeviceAttribEXT(reinterpret_cast<EGLDeviceEXT>(egl_device),
                                  EGL_D3D11_DEVICE_ANGLE,
                                  &angle_device) == EGL_TRUE) {
        d3d_11_device_ = reinterpret_cast<ID3D11Device*>(angle_device);
      }
    }
    if (!d3d_11_device_) {
      FAIL("Unable to query ID3D11Device from ANGLE.");
    }
#else
    auto feature_levels = {
        D3D_FEATURE_LEVEL_11_0,
        D3D_FEATURE_LEVEL_10_1,
        D3D_FEATURE_LEVEL_10_0,
        D3D_FEATURE_LEVEL_9_3,
    };
    // NOTE: Not enabling DirectX 12.
    // |D3D11CreateDevice| crashes directly on Windows 7.
    // D3D_FEATURE_LEVEL_12_2, D3D_FEATURE_LEVEL_12_1, D3D_FEATURE_LEVEL_12_0,
    // D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_1,
    // D3D_FEATURE_LEVEL_10_0, D3D_FEATURE_LEVEL_9_3,
    IDXGIFactory* dxgi = nullptr;
    ::CreateDXGIFactory(__uuidof(IDXGIFactory), (void**)&dxgi);
    // Manually selecting adapter. As far as my experience goes, this is the
    // safest approach. Passing `0` (so-called default) seems to cause issues
    // on Windows 7 or maybe some older graphics drivers.
    // First adapter is the default.
    // |D3D_DRIVER_TYPE_UNKNOWN| must be passed with manual adapter selection.
    dxgi->EnumAdapters(0, &adapter_);
    dxgi->Release();
    if (!adapter_) {
      FAIL("No IDXGIAdapter found.");
    }
    auto hr = ::D3D11CreateDevice(
        adapter_, D3D_DRIVER_TYPE_UNKNOWN, 0, 0, feature_levels.begin(),
        static_cast<UINT>(feature_levels.size()), D3D11_SDK_VERSION,
        &d3d_11_device_, 0, &d3d_11_device_context_);
    CHECK_HRESULT("D3D11CreateDevice");
#endif
  }

  Microsoft::WRL::ComPtr<IDXGIDevice> dxgi_device = nullptr;
  auto dxgi_device_success = d3d_11_device_->QueryInterface(
      __uuidof(IDXGIDevice), (void**)&dxgi_device);
  if (SUCCEEDED(dxgi_device_success) && dxgi_device != nullptr) {
    dxgi_device->SetGPUThreadPriority(5);  // Must be in interval [-7, 7].
  }

  auto level = d3d_11_device_->GetFeatureLevel();
  std::cout << "media_kit: ANGLESurfaceManager: Direct3D Feature Level: "
            << (((unsigned)level) >> 12) << "_"
            << ((((unsigned)level) >> 8) & 0xf) << std::endl;
  auto d3d11_texture2D_desc = D3D11_TEXTURE2D_DESC{0};
  d3d11_texture2D_desc.Width = width_;
  d3d11_texture2D_desc.Height = height_;
  d3d11_texture2D_desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  d3d11_texture2D_desc.MipLevels = 1;
  d3d11_texture2D_desc.ArraySize = 1;
  d3d11_texture2D_desc.SampleDesc.Count = 1;
  d3d11_texture2D_desc.SampleDesc.Quality = 0;
  d3d11_texture2D_desc.Usage = D3D11_USAGE_DEFAULT;
  d3d11_texture2D_desc.BindFlags =
      D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
  d3d11_texture2D_desc.CPUAccessFlags = 0;
  d3d11_texture2D_desc.MiscFlags = D3D11_RESOURCE_MISC_SHARED;
  auto hr = d3d_11_device_->CreateTexture2D(&d3d11_texture2D_desc, nullptr,
                                            &d3d11_texture_2D_);
  CHECK_HRESULT("ID3D11Device::CreateTexture2D");
  auto resource = Microsoft::WRL::ComPtr<IDXGIResource>{};
  hr = d3d11_texture_2D_.As(&resource);
  CHECK_HRESULT("ID3D11Texture2D::As");
  // IMPORTANT: Retrieve |handle_| for interop.
  hr = resource->GetSharedHandle(&handle_);
  CHECK_HRESULT("IDXGIResource::GetSharedHandle");
  CreateEGLDisplay();
  return true;
}

bool ANGLESurfaceManager::InitializeD3D9() {
  auto hr = ::Direct3DCreate9Ex(D3D_SDK_VERSION, &d3d_9_ex_);
  CHECK_HRESULT("Direct3DCreate9Ex");
  auto present_params = D3DPRESENT_PARAMETERS{};
  present_params.BackBufferWidth = width_;
  present_params.BackBufferHeight = height_;
  present_params.BackBufferFormat = D3DFMT_UNKNOWN;
  present_params.BackBufferCount = 1;
  present_params.SwapEffect = D3DSWAPEFFECT_DISCARD;
  present_params.hDeviceWindow = 0;
  present_params.Windowed = TRUE;
  present_params.Flags = D3DPRESENTFLAG_VIDEO;
  present_params.FullScreen_RefreshRateInHz = 0;
  present_params.PresentationInterval = 0;
  hr = d3d_9_ex_->CreateDeviceEx(
      D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, 0,
      D3DCREATE_FPU_PRESERVE | D3DCREATE_HARDWARE_VERTEXPROCESSING |
          D3DCREATE_DISABLE_PSGP_THREADING | D3DCREATE_MULTITHREADED,
      &present_params, 0, &d3d_9_device_ex_);
  CHECK_HRESULT("IDirect3D9Ex::CreateDeviceEx");
  // IMPORTANT: Retrieve |handle_| for interop.
  hr = d3d_9_device_ex_->CreateTexture(
      width_, height_, 1, D3DUSAGE_RENDERTARGET, D3DFMT_A8R8G8B8,
      D3DPOOL_DEFAULT, &d3d_9_texture_, &handle_);
  CHECK_HRESULT("IDirect3DDevice9Ex::CreateTexture");
  CreateEGLDisplay();
  return true;
}

void ANGLESurfaceManager::CleanUp(bool release_context) {
  if (release_context) {
    if (display_ != EGL_NO_DISPLAY) {
      eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
      eglReleaseTexImage(display_, surface_, EGL_BACK_BUFFER);
      eglTerminate(display_);
    }
    if (surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(display_, surface_);
      display_ = EGL_NO_SURFACE;
    }
    if (context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(display_, context_);
      context_ = EGL_NO_CONTEXT;
    }
    display_ = EGL_NO_DISPLAY;
    // Release D3D 11 resources.
    if (d3d_11_device_context_) {
      d3d_11_device_context_->Release();
      d3d_11_device_context_ = nullptr;
    }
    // Release ID3D11Device only if it was created by us (not by ANGLE).
#ifndef ENABLE_ID3D11DEVICE_FROM_ANGLE
    if (d3d_11_device_) {
      d3d_11_device_->Release();
      d3d_11_device_ = nullptr;
    }
#endif
    // Release D3D 9 resources.
    if (d3d_9_texture_) {
      d3d_9_texture_->Release();
      d3d_9_texture_ = nullptr;
    }
    if (d3d_9_device_ex_) {
      d3d_9_device_ex_->Release();
      d3d_9_device_ex_ = nullptr;
    }
    if (d3d_9_ex_) {
      d3d_9_ex_->Release();
      d3d_9_ex_ = nullptr;
    }
  } else {
    // Clear context & destroy existing |surface_|.
    eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, context_);
#ifdef ENABLE_GL_FINISH_SAFEGUARD
    glFinish();
#endif
    if (display_ != EGL_NO_DISPLAY && surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(display_, surface_);
    }
    surface_ = EGL_NO_SURFACE;
  }
}

bool ANGLESurfaceManager::CreateAndBindEGLSurface() {
  // Do not create |context_| again, likely due to |Resize|.
  if (context_ == EGL_NO_CONTEXT) {
    // First time from the constructor itself.
    auto count = 0;
    auto result = eglChooseConfig(display_, kEGLConfigurationAttributes,
                                  &config_, 1, &count);
    if (result == EGL_FALSE || count == 0) {
      FAIL("eglChooseConfig");
    }
    context_ = eglCreateContext(display_, config_, EGL_NO_CONTEXT,
                                kEGLContextAttributes);
    if (context_ == EGL_NO_CONTEXT) {
      FAIL("eglCreateContext");
    }
  }
  EGLint buffer_attributes[] = {
      EGL_WIDTH,          width_,         EGL_HEIGHT,         height_,
      EGL_TEXTURE_TARGET, EGL_TEXTURE_2D, EGL_TEXTURE_FORMAT, EGL_TEXTURE_RGBA,
      EGL_NONE,
  };
  surface_ = eglCreatePbufferFromClientBuffer(
      display_, EGL_D3D_TEXTURE_2D_SHARE_HANDLE_ANGLE, handle_, config_,
      buffer_attributes);
  if (surface_ == EGL_NO_SURFACE) {
    FAIL("eglCreatePbufferFromClientBuffer");
  }
  GLuint t;
  glGenTextures(1, &t);
  glBindTexture(GL_TEXTURE_2D, t);
  eglBindTexImage(display_, surface_, EGL_BACK_BUFFER);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  return true;
}
