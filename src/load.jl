# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

function load(fname; kwargs...)
  tiff = TiffImages.load(fname; kwargs...)
  metadata = _getmetadata(tiff)
  GeoTIFFImage(tiff, metadata)
end

# -----------------
# HELPER FUNCTIONS
# -----------------

function _getmetadata(tiff)
  ifd = TiffImages.ifds(tiff)
  geokeydirectory = _gettag(ifd, GeoKeyDirectoryTag, GeoKeyDirectory)
  geodoubleparams = _gettag(ifd, GeoDoubleParamsTag, GeoDoubleParams)
  geoasciiparams = _gettag(ifd, GeoAsciiParamsTag, GeoAsciiParams)
  modelpixelscale = _gettag(ifd, ModelPixelScaleTag, ModelPixelScale)
  modeltiepoint = _gettag(ifd, ModelTiepointTag, ModelTiepoint)
  modeltransformation = _gettag(ifd, ModelTransformationTag, ModelTransformation)
  Metadata(; geokeydirectory, geodoubleparams, geoasciiparams, modelpixelscale, modeltiepoint, modeltransformation)
end

function _gettag(ifd, tag, Type)
  params = TiffImages.getdata(ifd, UInt16(tag), nothing)
  isnothing(params) && return nothing
  Type(params)
end
