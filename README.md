# GeoTIFF.jl

[![Build Status](https://github.com/JuliaEarth/GeoTIFF.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaEarth/GeoTIFF.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaEarth/GeoTIFF.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaEarth/GeoTIFF.jl)

Load and save GeoTIFF files in native Julia.

## Installation

Get the latest stable release with Julia's package manager:

```
] add GeoTIFF
```

## Usage

### Loading GeoTIFF files

The `GeoTIFF.load` function loads the TIFF image,
using the [TiffImages.jl](https://github.com/tlnagy/TiffImages.jl) package,
and the GeoTIFF metadata:

```julia
julia> geotiff = GeoTIFF.load("utm.tif")
100×100 GeoTIFF.GeoTIFFImage{...}:
 RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  …  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)
 RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)     RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)
 RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)     RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)
 ⋮                                                                               ⋱                                          
 RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)     RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)
 RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)     RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)  RGB(1.0, 1.0, 1.0)
```

Use the `GeoTIFF.metadata` to get the metadata object:

```julia
julia> metadata = GeoTIFF.metadata(geotiff)
GeoTIFF.Metadata(...)
```

GeoTIFF.jl defines several utilities to easily retrieve metadata information:

```julia
julia> GeoTIFF.rastertype(metadata) == GeoTIFF.PixelIsArea
true

julia> GeoTIFF.modeltype(metadata) == GeoTIFF.Projected2D
true

julia> GeoTIFF.epsgcode(metadata) |> Int # GeoTIFF uses UInt16 for integer values
32617
```

### Saving GeoTIFF files

The `GeoTIFF.save` function can be used to save tiff images, color arrays,
or channel arrays into new GeoTIFF files with given metadata:

```julia
julia> using Colors

julia> GeoTIFF.save("geotiff.tiff", geotiff)

julia> colors = rand(Gray{Float64}, 100, 100);

julia> GeoTIFF.save("colors.tiff", colors) # default metadata

julia> channel1 = rand(100, 100);

julia> channel2 = rand(100, 100);

julia> channel3 = rand(100, 100);

julia> channel4 = rand(100, 100);

julia> GeoTIFF.save("channels.tiff", channel1, channel2, channel3, channel4) # default metadata
```

Use the `GeoTIFF.metadata` function to easily construct new GeoTIFF metadata to georeference the image:

```julia
julia> img = rand(Gray{Float64}, 100, 100);

julia> A = [3.6 0.0; 0.0 1.8]; # scale grid((0, 0), (100, 100)) to grid((0, 0), (360, 180))

julia> b = [-180.0, -90.0]; # translete grid((0, 0), (360, 180)) to grid((-180, -90), (180, 90)) (latlon coordinates)

julia> metadata = GeoTIFF.metadata(
         rastertype=GeoTIFF.PixelIsArea, 
         modeltype=GeoTIFF.Geographic2D,
         geodeticcrs=4326, # EPSG 4326: WGS 84 latlon
         transformation=(A, b) # raster-to-model transformation
       );

julia> GeoTIFF.save("latlon.tiff", img, metadata=metadata)
```

Please read the docstrings for more details.
