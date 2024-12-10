# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

"""
    GeoTIFF.load(fname; kwargs...)

Load a GeoTIFF file returning an image with the processed GeoTIFF metadata.
If the file contains more than one image, an iterator of images will be returned.
The keyword arguments are forward to the `TiffImages.load` function.

See also [`GeoTIFF.GeoTIFFImage`](@ref), [`GeoTIFF.GeoTIFFImageIterator`](@ref).

### Notes

* TIFF files without GeoTIFF metadata are load with default and mandatory metadata:
  * [`GeoKeyDirectory`](@ref) without GeoKeys and only with GeoTIFF version.
  * [`ModelTransformation`](@ref) with `A` as identity matrix and `b` as vector of zeros.
"""
function load(fname; kwargs...)
  tiff = TiffImages.load(fname; kwargs...)
  ifds = TiffImages.ifds(tiff)
  metadata = ifds isa IFD ? _getmetadata(ifds) : (_getmetadata(ifd) for ifd in ifds)
  if tiff isa StridedTaggedImage
    GeoTIFFImageIterator(tiff, metadata)
  elseif ndims(tiff) == 3
    imgs = eachslice(tiff, dims=3)
    GeoTIFFImageIterator(imgs, metadata)
  else
    GeoTIFFImage(tiff, metadata)
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
