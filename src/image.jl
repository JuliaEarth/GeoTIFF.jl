# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

struct GeoTIFFImage{T,N,I<:AbstractTIFF{T,N}} <: AbstractArray{T,N}
  tiff::I
  metadata::Metadata
end

tiff(geotiff::GeoTIFFImage) = geotiff.tiff

metadata(geotiff::GeoTIFFImage) = geotiff.metadata

# AbstractArray interface
Base.size(geotiff::GeoTIFFImage) = size(geotiff.tiff)
Base.getindex(geotiff::GeoTIFFImage, i...) = getindex(geotiff.tiff, i...)
Base.setindex!(geotiff::GeoTIFFImage, v, i...) = setindex!(geotiff.tiff, v, i...)
Base.IndexStyle(::Type{GeoTIFFImage{T,N,I}}) where {T,N,I} = IndexStyle(I)
