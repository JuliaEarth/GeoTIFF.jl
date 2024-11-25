# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

"""
    GeoTIFF.geokey(metadata, id)

Find the GeoKey that has the `id` in the `metadata`.
If it is not stored in the metadata, `nothing` will be returned.
"""
function geokey(metadata::Metadata, id::GeoKeyID)
  geokeys = metadata.geokeydirectory.geokeys
  i = findfirst(geokey -> geokey.id == id, geokeys)
  isnothing(i) ? nothing : geokeys[i]
end

"""
    GeoTIFF.geokeyvalue(metadata, id)

Find the GeoKey that has the `id` in the `metadata` and return it value.
If it is not stored in the metadata, `nothing` will be returned.
"""
function geokeyvalue(metadata::Metadata, id::GeoKeyID)
  gk = geokey(metadata, id)
  isnothing(gk) ? nothing : gk.value
end

"""
    GeoTIFF.geokeydouble(metadata, id)

Find the GeoKey that has the `id` in the `metadata` and return it double parameter.
If it is not stored in the metadata, `nothing` will be returned.
"""
function geokeydouble(metadata::Metadata, id::GeoKeyID)
  dp = metadata.geodoubleparams
  gk = geokey(metadata, id)
  if isnothing(dp) || isnothing(gk) || gk.count > 1
    nothing
  else
    dp.params[gk.value + 1]
  end
end

"""
    GeoTIFF.geokeyascii(metadata, id)

Find the GeoKey that has the `id` in the metadata and return it ASCII parameter.
If it is not stored in the metadata, `nothing` will be returned.
"""
function geokeyascii(metadata::Metadata, id::GeoKeyID)
  ap = metadata.geoasciiparams
  gk = geokey(metadata, id)
  if isnothing(ap) || isnothing(gk)
    nothing
  else
    str = ap.params[(gk.value + 1):(gk.value + gk.count)]
    rstrip(str, '|') # terminator
  end
end

"""
    GeoTIFF.rastertype(metadata)

Raster type of the GeoTIFF. If it is not stored in the `metadata`, `nothing` will be returned.
"""
rastertype(metadata::Metadata) = geokeyvalue(metadata, GTRasterTypeGeoKey)

"""
    GeoTIFF.modeltype(metadata)

Model type of the GeoTIFF. If it is not stored in the `metadata`, `nothing` will be returned.
"""
modeltype(metadata::Metadata) = geokeyvalue(metadata, GTModelTypeGeoKey)

"""
    GeoTIFF.epsgcode(metadata)

EPSG Code of the GeoTIFF CRS. If it is not stored in the `metadata`, `nothing` will be returned.
"""
function epsgcode(metadata::Metadata)
  mt = modeltype(metadata)
  isnothing(mt) && return nothing
  if mt == Projected2D
    geokeyvalue(metadata, ProjectedCRSGeoKey)
  elseif mt == Geographic2D || mt == Geocentric3D
    geokeyvalue(metadata, GeodeticCRSGeoKey)
  else
    # Undefined or UserDefined
    nothing
  end
end

"""
    GeoTIFF.affineparams2D(metadata)

Affine 2D parameters `(A, b)` of the GeoTIFF raster-to-model transformation. 
If it is not stored in the `metadata`, `nothing` will be returned.
"""
function affineparams2D(metadata::Metadata)
  pixelscale = metadata.modelpixelscale
  tiepoint = metadata.modeltiepoint
  transformation = metadata.modeltransformation
  if !isnothing(pixelscale) && !isnothing(tiepoint)
    sx = pixelscale.x
    sy = pixelscale.y
    (; i, j, x, y) = tiepoint
    tx = x - i / sx
    ty = y + j / sy
    A = SA[
      sx 0
      0 -sy
    ]
    b = SA[tx, ty]
    A, b
  elseif !isnothing(transformation)
    Aₜ = transformation.A
    bₜ = transformation.b
    A = SA[
      Aₜ[1, 1] Aₜ[1, 2]
      Aₜ[2, 1] Aₜ[2, 2]
    ]
    b = SA[bₜ[1], bₜ[2]]
    A, b
  else
    nothing
  end
end

"""
    GeoTIFF.affineparams3D(metadata)

Affine 3D parameters `(A, b)` of the GeoTIFF raster-to-model transformation. 
If it is not stored in the `metadata`, `nothing` will be returned.
"""
function affineparams3D(metadata::Metadata)
  pixelscale = metadata.modelpixelscale
  tiepoint = metadata.modeltiepoint
  transformation = metadata.modeltransformation
  if !isnothing(pixelscale) && !isnothing(tiepoint)
    sx = pixelscale.x
    sy = pixelscale.y
    sz = pixelscale.z
    (; i, j, k, x, y, z) = tiepoint
    tx = x - i / sx
    ty = y + j / sy
    tz = z - k / sz
    A = SA[
      sx 0 0
      0 -sy 0
      0 0 sz
    ]
    b = SA[tx, ty, tz]
    A, b
  elseif !isnothing(transformation)
    transformation.A, transformation.b
  else
    nothing
  end
end
