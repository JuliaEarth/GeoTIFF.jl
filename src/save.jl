# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

const GeoTIFFType = Union{AbstractFloat,Signed,Unsigned}

const WidePixelOrColorant = Union{WidePixel,Colorant}

"""
    GeoTIFF.save(fname, geotiff)

Save in the file `fname` a `geotiff` image returned by the [`GeoTIFF.load`](@ref) function.
"""
save(fname, geotiff::GeoTIFFImage) = TiffImages.save(fname, tiff(geotiff))

"""
    GeoTIFF.save(fname, tiff; metadata=GeoTIFF.Metadata())

Save in the file `fname` a `tiff` image with passed GeoTIFF `metadata`.
"""
function save(fname, tiff::AbstractTIFF; metadata=Metadata())
  _setmetadata!(tiff, metadata)
  TiffImages.save(fname, tiff)
end

"""
    GeoTIFF.save(fname, img; metadata=GeoTIFF.Metadata())

Save in the file `fname` an image (array of colors) `img` with passed GeoTIFF `metadata`.
"""
save(fname, img::AbstractArray{<:WidePixelOrColorant}; kwargs...) = save(fname, DenseTaggedImage(img); kwargs...)

"""
    GeoTIFF.save(fname, channels...; metadata=GeoTIFF.Metadata())

Save in the file `fname` a multi-channel image with passed GeoTIFF `metadata`.
All `channels` must have the same size and an eltype supported by GeoTIFF, which are float, signed and unsigned integer.
"""
function save(fname, channel₁::AbstractArray{T}, channelₙ::AbstractArray{T}...; kwargs...) where {T<:GeoTIFFType}
  CT = _colordatatype(T)
  colors = reinterpret(Gray{CT}, channel₁)
  img = if length(channelₙ) > 0
    extras = reinterpret.(CT, channelₙ)
    mappedarray((color, extra...) -> WidePixel(color, extra), colors, extras...)
  else
    colors
  end
  save(fname, img; kwargs...)
end

# -----------------
# HELPER FUNCTIONS
# -----------------

_colordatatype(::Type{T}) where {T<:AbstractFloat} = T
_colordatatype(::Type{T}) where {T<:Unsigned} = Normed{T,sizeof(T) * 8}
_colordatatype(::Type{T}) where {T<:Signed} = Fixed{T,sizeof(T) * 8 - 1}

function _setmetadata!(tiff, metadata)
  ifd = TiffImages.ifds(tiff)
  _settag!(ifd, GeoKeyDirectoryTag, metadata.geokeydirectory)
  _settag!(ifd, GeoDoubleParamsTag, metadata.geodoubleparams)
  _settag!(ifd, GeoAsciiParamsTag, metadata.geoasciiparams)
  _settag!(ifd, ModelPixelScaleTag, metadata.modelpixelscale)
  _settag!(ifd, ModelTiepointTag, metadata.modeltiepoint)
  _settag!(ifd, ModelTransformationTag, metadata.modeltransformation)
end

function _settag!(ifd, tag, geotag)
  if !isnothing(geotag)
    ifd[UInt16(tag)] = params(geotag)
  end
end
