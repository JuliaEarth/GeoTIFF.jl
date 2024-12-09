# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

"""
    GeoTIFF.GeoTIFFImage

Image type returned by the [`GeoTIFF.load`](@ref) function.

See the [`GeoTIFF.metadata`](@ref) and [`GeoTIFF.image`](@ref) functions
to get the metadata and the image with corrected axes, respectively.

### Notes

* The [`GeoTIFF.image`](@ref) function is necessary because 
  the GeoTIFF format swaps the order of the image axes;
"""
struct GeoTIFFImage{T,I<:AbstractMatrix{T}} <: AbstractMatrix{T}
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
    GeoTIFF.image(geotiff)

Image of the `geotiff` with corrected axis.
"""
image(geotiff::GeoTIFFImage) = PermutedDimsArray(geotiff.tiff, (2, 1))

"""
    GeoTIFF.nchannels(geotiff)

Number of channels of the `geotiff` image.
"""
nchannels(geotiff::GeoTIFFImage) = nchannels(geotiff.tiff)

"""
    GeoTIFF.channel(geotiff, i)

`i`'th channel of the `geotiff` image.
"""
channel(geotiff::GeoTIFFImage, i) = mappedarray(c -> channel(c, i), image(geotiff))

# AbstractArray interface
Base.size(geotiff::GeoTIFFImage) = size(geotiff.tiff)
Base.getindex(geotiff::GeoTIFFImage, i...) = getindex(geotiff.tiff, i...)
Base.setindex!(geotiff::GeoTIFFImage, v, i...) = setindex!(geotiff.tiff, v, i...)
Base.IndexStyle(::Type{GeoTIFFImage{T,I}}) where {T,I} = IndexStyle(I)

struct GeoTIFFIterator{I,M}
  tiffs::I
  metadata::M
end

Base.length(geotiffs::GeoTIFFIterator) = length(geotiffs.tiffs)

function Base.iterate(geotiffs::GeoTIFFIterator)
  tiff, stateₜ = iterate(geotiffs.tiffs)
  metadata, stateₘ = iterate(geotiffs.metadata)
  GeoTIFFImage(tiff, metadata), (stateₜ, stateₘ)
end

function Base.iterate(geotiffs::GeoTIFFIterator, (stateₜ, stateₘ))
  valueₜ = iterate(geotiffs.tiffs, stateₜ)
  valueₘ = iterate(geotiffs.metadata, stateₘ)
  if !isnothing(valueₜ) && !isnothing(valueₘ)
    tiff, newstateₜ = valueₜ
    metadata, newstateₘ = valueₘ
    GeoTIFFImage(tiff, metadata), (newstateₜ, newstateₘ)
  else
    nothing
  end
end
