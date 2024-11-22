# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

"""
    GeoTIFF.GeoTIFFImage

Image type returned by the [`GeoTIFF.load`](@ref) function.

See the [`GeoTIFF.tiff`](@ref) and [`GeoTIFF.metadata`](@ref) functions
to get the TIFF image and metadata respectively.
"""
struct GeoTIFFImage{T,N,I<:AbstractTIFF{T,N}} <: AbstractArray{T,N}
  tiff::I
  metadata::Metadata
end

"""
    GeoTIFF.tiff(geotiff)

TIFF image of the `geotiff` image.
"""
tiff(geotiff::GeoTIFFImage) = geotiff.tiff

"""
    GeoTIFF.metadata(geotiff)

GeoTIFF metadata of the `geotiff` image.
"""
metadata(geotiff::GeoTIFFImage) = geotiff.metadata

"""
    GeoTIFF.nchannels(geotiff)

Number of channels of the `geotiff` image.
"""
nchannels(geotiff::GeoTIFFImage) = nchannels(geotiff.tiff)

"""
    GeoTIFF.channel(geotiff, i)

`i`'th channel of the `geotiff` image.
"""
function channel(geotiff::GeoTIFFImage, i)
  C = mappedarray(c -> channel(c, i), geotiff.tiff)
  PermutedDimsArray(C, (2, 1))
end

# AbstractArray interface
Base.size(geotiff::GeoTIFFImage) = reverse(size(geotiff.tiff))
Base.getindex(geotiff::GeoTIFFImage, i, j) = getindex(geotiff.tiff, j, i)
Base.setindex!(geotiff::GeoTIFFImage, v, i, j) = setindex!(geotiff.tiff, v, j, i)
Base.IndexStyle(::Type{GeoTIFFImage{T,N,I}}) where {T,N,I} = IndexStyle(I)
