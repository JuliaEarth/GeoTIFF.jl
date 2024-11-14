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

TIFF image of a `geotiff` image.
"""
tiff(geotiff::GeoTIFFImage) = geotiff.tiff

"""
    GeoTIFF.metadata(geotiff)

GeoTIFF metadata of a `geotiff` image.
"""
metadata(geotiff::GeoTIFFImage) = geotiff.metadata

# AbstractArray interface
Base.size(geotiff::GeoTIFFImage) = size(geotiff.tiff)
Base.getindex(geotiff::GeoTIFFImage, i...) = getindex(geotiff.tiff, i...)
Base.setindex!(geotiff::GeoTIFFImage, v, i...) = setindex!(geotiff.tiff, v, i...)
Base.IndexStyle(::Type{GeoTIFFImage{T,N,I}}) where {T,N,I} = IndexStyle(I)
