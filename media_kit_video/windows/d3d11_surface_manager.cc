// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#include "d3d11_surface_manager.h"

#include <iostream>
#include <sstream>
#include <stdexcept>

namespace {
void Check(HRESULT result, const char* operation) {
  if (FAILED(result)) {
    std::ostringstream message;
    message << operation << " failed (HRESULT 0x" << std::hex
            << static_cast<unsigned long>(result) << ")";
    throw std::runtime_error(message.str());
  }
}
}  // namespace

D3D11SurfaceManager::D3D11SurfaceManager(IDXGIAdapter* adapter) {
  if (!adapter)
    throw std::runtime_error("Flutter graphics adapter unavailable");
  Check(D3D11CreateDevice(adapter, D3D_DRIVER_TYPE_UNKNOWN, nullptr,
                          D3D11_CREATE_DEVICE_BGRA_SUPPORT, nullptr, 0,
                          D3D11_SDK_VERSION, &device_, nullptr, nullptr),
        "D3D11CreateDevice");
  if (device_->GetFeatureLevel() < D3D_FEATURE_LEVEL_10_0)
    throw std::runtime_error("D3D11 feature level 10_0 or later is required");
  Check(device_.As(&dxgi_), "Query IDXGIDevice2");
  DXGI_ADAPTER_DESC desc{};
  Check(adapter->GetDesc(&desc), "Get adapter description");
  std::ostringstream info;
  info << "media_kit: D3D11 adapter LUID " << std::hex
       << desc.AdapterLuid.HighPart << ":" << desc.AdapterLuid.LowPart
       << ", feature level 0x" << device_->GetFeatureLevel();
  std::cout << info.str() << std::endl;
}

std::shared_ptr<D3D11SurfaceManager::Surface>
D3D11SurfaceManager::CreateSurface(int width, int height) const {
  D3D11_TEXTURE2D_DESC desc{};
  desc.Width = width;
  desc.Height = height;
  desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  desc.ArraySize = desc.MipLevels = desc.SampleDesc.Count = 1;
  desc.Usage = D3D11_USAGE_DEFAULT;
  desc.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
  desc.MiscFlags = D3D11_RESOURCE_MISC_SHARED;
  auto surface = std::make_shared<Surface>();
  Check(device_->CreateTexture2D(&desc, nullptr, &surface->texture),
        "CreateTexture2D");
  Microsoft::WRL::ComPtr<IDXGIResource> resource;
  Check(surface->texture.As(&resource), "Query IDXGIResource");
  Check(resource->GetSharedHandle(&surface->handle), "GetSharedHandle");
  return surface;
}

void D3D11SurfaceManager::WaitForWrites() {
  // Wait for GPU writes on the producer thread before Flutter reads the surface.
  // The producer leaves the surface unchanged after publication.
  if (!completed_.IsValid()) {
    completed_.Attach(CreateEventW(nullptr, FALSE, FALSE, nullptr));
    if (!completed_.IsValid())
      throw std::runtime_error("Cannot create D3D11 completion event");
  }
  Check(dxgi_->EnqueueSetEvent(completed_.Get()), "EnqueueSetEvent");
  if (WaitForSingleObject(completed_.Get(), 2000) != WAIT_OBJECT_0) {
    // Discard this event so a late signal cannot release the next frame.
    completed_.Close();
    throw std::runtime_error("D3D11 frame completion wait failed");
  }
  Check(device_->GetDeviceRemovedReason(), "D3D11 frame completion");
}
