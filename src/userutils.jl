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
"""
function affineparams2D(metadata::Metadata)
  A3D, b3D = affineparams3D(metadata)
  A = SA[
    A3D[1, 1] A3D[1, 2]
    A3D[2, 1] A3D[2, 2]
  ]
  b = SA[b3D[1], b3D[2]]
  A, b
end

"""
    GeoTIFF.affineparams3D(metadata)

Affine 3D parameters `(A, b)` of the GeoTIFF raster-to-model transformation.
"""
function affineparams3D(metadata::Metadata)
  # The general formula for raster-to-model transformations is:
  # T(ijk - ijkₜ) + xyzₜ
  # where T is a transformation that converts raster coordinates ijk
  # to model coordinates xyz, i.e.: T(ijk) -> xyz,
  # ijkₜ is a shift in raster coordinates,
  # and xyzₜ is a shift in model coordinates.
  # Both ijkₜ and xyzₜ are defined in Tiepoint.
  tiepoint = metadata.modeltiepoint
  pixelscale = metadata.modelpixelscale
  transformation = metadata.modeltransformation
  ijkₜ = SA[tiepoint.i, tiepoint.j, tiepoint.k]
  xyzₜ = SA[tiepoint.x, tiepoint.y, tiepoint.z]
  if !isnothing(pixelscale)
    # Pixel Scale
    # T(ijk) = S * ijk
    # Replacing in the formula:
    # S * (ijk - ijkₜ) + xyzₜ
    # Rearranging in affine form:
    # S * ijk + (xyzₜ - S * ijkₜ)
    sx = pixelscale.x
    sy = pixelscale.y
    sz = pixelscale.z
    S = SA[
      sx 0.0 0.0
      0.0 -sy 0.0
      0.0 0.0 sz
    ]
    A = S
    b = xyzₜ - S * ijkₜ
  elseif !isnothing(transformation)
    # Model Transformation
    # T(ijk) = Aₜ * ijk + bₜ
    # Replacing in the formula:
    # (Aₜ * (ijk - ijkₜ) + bₜ) + xyzₜ
    # Rearranging in affine form:
    # Aₜ * ijk + (bₜ + xyzₜ - Aₜ * ijkₜ)
    Aₜ = transformation.A
    bₜ = transformation.b
    A = Aₜ
    b = bₜ + xyzₜ - Aₜ * ijkₜ
  else
    # Identity (Tiepoint only)
    # T(ijk) = I * ijk
    # Replacing in the formula:
    # I * (ijk - ijkₜ) + xyzₜ
    # Rearranging in affine form:
    # I * ijk + (xyzₜ - I * ijkₜ)
    # or
    # I * ijk + (xyzₜ - ijkₜ)
    I = SA[
      1.0 0.0 0.0
      0.0 1.0 0.0
      0.0 0.0 1.0
    ]
    A = I
    b = xyzₜ - ijkₜ
  end
  A, b
end
