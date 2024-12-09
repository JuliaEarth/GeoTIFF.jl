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

abstract type MultiGeoTIFF end

function getgeotiff end

function ngeotiffs end

# Iterator interface
Base.length(geotiff::MultiGeoTIFF) = ngeotiffs(geotiff)
Base.iterate(geotiff::MultiGeoTIFF, state=1) =
  state > length(geotiff) ? nothing : (getgeotiff(geotiff, state), state + 1)

# Indexing interface
Base.getindex(geotiff::MultiGeoTIFF, i) = getgeotiff(geotiff, i)
Base.firstindex(geotiff::MultiGeoTIFF) = 1
Base.lastindex(geotiff::MultiGeoTIFF) = ngeotiffs(geotiff)

struct StridedGeoTIFF{I<:StridedTaggedImage} <: MultiGeoTIFF
  tiff::I
  metadata::Vector{Metadata}
end

ngeotiffs(geotiff::StridedGeoTIFF) = length(geotiff.tiff)
getgeotiff(geotiff::StridedGeoTIFF, i) = GeoTIFFImage(geotiff.tiff[i], geotiff.metadata[i])

struct SlicedGeoTIFF{T,I<:AbstractTIFF{T,3}} <: MultiGeoTIFF
  tiff::I
  metadata::Vector{Metadata}
end

ngeotiffs(geotiff::SlicedGeoTIFF) = size(geotiff.tiff, 3)
getgeotiff(geotiff::SlicedGeoTIFF, i) = GeoTIFFImage(@view(geotiff.tiff[:, :, i]), geotiff.metadata[i])
