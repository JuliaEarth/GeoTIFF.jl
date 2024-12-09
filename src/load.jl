# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

"""
    GeoTIFF.load(fname; kwargs...)

Load a GeoTIFF file returning an image with the processed GeoTIFF metadata.
The keyword arguments are forward to the `TiffImages.load` function.

### Notes

* TIFF files without GeoTIFF metadata are load with default and mandatory metadata:
  * [`GeoKeyDirectory`](@ref) without GeoKeys and only with GeoTIFF version.
  * [`ModelTransformation`](@ref) with `A` as identity matrix and `b` as vector of zeros.
"""
function load(fname; kwargs...)
  geotiff(img, ifd) = GeoTIFFImage(img, _getmetadata(ifd))
  tiff = TiffImages.load(fname; kwargs...)
  ifds = TiffImages.ifds(tiff)
  if tiff isa StridedTaggedImage
    GeoTIFFImages(geotiff.(tiff, ifds))
  elseif ndims(tiff) == 3
    imgs = eachslice(tiff, dims=3)
    GeoTIFFImages(geotiff.(imgs, ifds))
  else
    geotiff(tiff, ifds)
  end
end

# -----------------
# HELPER FUNCTIONS
# -----------------

function _getmetadata(ifd)
  geokeydirectory = _gettag(ifd, GeoKeyDirectoryTag, GeoKeyDirectory)
  geodoubleparams = _gettag(ifd, GeoDoubleParamsTag, GeoDoubleParams)
  geoasciiparams = _gettag(ifd, GeoAsciiParamsTag, GeoAsciiParams)
  modelpixelscale = _gettag(ifd, ModelPixelScaleTag, ModelPixelScale)
  modeltiepoint = _gettag(ifd, ModelTiepointTag, ModelTiepoint)
  modeltransformation = _gettag(ifd, ModelTransformationTag, ModelTransformation)
  # support tiff files without metadata
  geokeydirectory′ = isnothing(geokeydirectory) ? GeoKeyDirectory() : geokeydirectory
  modeltransformation′ = if isnothing(modelpixelscale) && isnothing(modeltiepoint) && isnothing(modeltransformation)
    ModelTransformation()
  else
    modeltransformation
  end
  Metadata(;
    geokeydirectory=geokeydirectory′,
    geodoubleparams,
    geoasciiparams,
    modelpixelscale,
    modeltiepoint,
    modeltransformation=modeltransformation′
  )
end

function _gettag(ifd, tag, Type)
  params = TiffImages.getdata(ifd, UInt16(tag), nothing)
  isnothing(params) && return nothing
  Type(params)
end
