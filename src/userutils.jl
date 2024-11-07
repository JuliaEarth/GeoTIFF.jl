# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

function geokey(metadata::Metadata, id::GeoKeyID)
  geokeys = metadata.geokeydirectory.geokeys
  i = findfirst(geokey -> geokey.id == id, geokeys)
  isnothing(i) ? nothing : geokeys[i]
end

function geokeyvalue(metadata::Metadata, id::GeoKeyID)
  gk = geokey(metadata, id)
  isnothing(gk) ? nothing : gk.value
end

rastertype(metadata::Metadata) = geokeyvalue(metadata, GTRasterTypeGeoKey)

modeltype(metadata::Metadata) = geokeyvalue(metadata, GTModelTypeGeoKey)

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
    transformation.A[1:2, 1:2], transformation.b[1:2]
  else
    nothing
  end
end

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
