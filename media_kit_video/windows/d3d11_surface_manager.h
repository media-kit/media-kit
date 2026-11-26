// This file is a part of media_kit
// (https://github.com/media-kit/media-kit).
//
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the
// LICENSE file.
#pragma once

#include <d3d11.h>
#include <dxgi1_2.h>
#include <wrl/client.h>
#include <wrl/wrappers/corewrappers.h>

#include <memory>

class D3D11SurfaceManager {
 public:
  struct Surface {
    Microsoft::WRL::ComPtr<ID3D11Texture2D> texture;
    HANDLE handle = nullptr;  // Borrowed legacy DXGI handle, owned by texture.
  };

  explicit D3D11SurfaceManager(IDXGIAdapter* adapter);
  ID3D11Device* device() const { return device_.Get(); }
  std::shared_ptr<Surface> CreateSurface(int width, int height) const;
  void WaitForWrites();

 private:
  Microsoft::WRL::ComPtr<ID3D11Device> device_;
  Microsoft::WRL::ComPtr<IDXGIDevice2> dxgi_;
  Microsoft::WRL::Wrappers::Event completed_;
};
