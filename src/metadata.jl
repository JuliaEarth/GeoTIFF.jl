# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

@enum GeoTag::UInt16 begin
  GeoKeyDirectoryTag = 34735
  GeoDoubleParamsTag = 34736
  GeoAsciiParamsTag = 34737
  ModelPixelScaleTag = 33550
  ModelTiepointTag = 33922
  ModelTransformationTag = 34264
end

# Corresponding names in the GeoTIFF specification:
# version - KeyDirectoryVersion
# revision - KeyRevision
# minor - MinorRevision
# nkeys - NumberOfKeys
# geokeys - Key Entry Set
struct GeoKeyDirectory
  version::UInt16
  revision::UInt16
  minor::UInt16
  nkeys::UInt16
  geokeys::Vector{GeoKey}
end

GeoKeyDirectory(; version=1, revision=1, minor=1, geokeys=GeoKey[]) =
  GeoKeyDirectory(version, revision, minor, length(geokeys), geokeys)

function GeoKeyDirectory(params::Vector{UInt16})
  nkeys = params[4]
  geokeys = map((1:nkeys) * 4) do i
    id = GeoKeyID(geokey[1 + i])
    tag = geokey[2 + i]
    count = geokey[3 + i]
    value = geokey[4 + i]
    GeoKey(id, tag, count, value)
  end

  version = params[1]
  revision = params[2]
  minor = params[3]
  GeoKeyDirectory(version, revision, minor, nkeys, geokeys)
end

function params(geokeydirectory::GeoKeyDirectory)
  params = [geokeydirectory.version, geokeydirectory.revision, geokeydirectory.minor, geokeydirectory.nkeys]
  for geokey in geokeydirectory.geokeys
    append!(params, [UInt16(geokey.id), geokey.tag, geokey.count, geokey.value])
  end
  params
end

struct GeoDoubleParams
  params::Vector{Float64}
end

params(geodoubleparams::GeoDoubleParams) = geodoubleparams.params

struct GeoAsciiParams
  params::String
end

params(geoasciiparams::GeoAsciiParams) = geoasciiparams.params

struct ModelPixelScale
  x::Float64
  y::Float64
  z::Float64
end

ModelPixelScale(; x=1.0, y=1.0, z=1.0) = ModelPixelScale(x, y, z)

ModelPixelScale(params::Vector{Float64}) = ModelPixelScale(params[1], params[2], params[3])

params(modelpixelscale::ModelPixelScale) = [modelpixelscale.x, modelpixelscale.y, modelpixelscale.z]

struct ModelTiepoint
  i::Float64
  j::Float64
  k::Float64
  x::Float64
  y::Float64
  z::Float64
end

ModelTiepoint(; i=0.0, j=0.0, k=0.0, x=0.0, y=0.0, z=0.0) = ModelTiepoint(i, j, k, x, y, z)

ModelTiepoint(params::Vector{Float64}) = ModelTiepoint(params[1], params[2], params[3], params[4], params[5], params[6])

params(modeltiepoint::ModelTiepoint) =
  [modeltiepoint.i, modeltiepoint.j, modeltiepoint.k, modeltiepoint.x, modeltiepoint.y, modeltiepoint.z]

struct ModelTransformation
  A::Matrix{Float64}
  b::Vector{Float64}
end

function ModelTransformation(; A=_A, b=_b)
  sz = size(A)
  if !allequal(sz)
    throw(ArgumentError("`A` must be a square matrix"))
  end
  dim = first(sz)
  if dim ≠ length(b)
    throw(ArgumentError("`A` and `b` must have the same dimension"))
  end
  A′, b′ = if dim == 2
    [A[1, 1] A[1, 2] 0; A[2, 1] A[2, 2] 0; 0 0 0], [b[1], b[2], 0]
  elseif dim == 3
    A, b
  else
    throw(ArgumentError("only 2D and 3D transformations are supported"))
  end
  ModelTransformation(A′, b′)
end

function ModelTransformation(params::Vector{Float64})
  A = [
    params[1] params[2] params[3]
    params[5] params[6] params[7]
    params[9] params[10] params[11]
  ]
  b = [params[4], params[8], params[12]]
  ModelTransformation(A, b)
end

function params(modeltransformation::ModelTransformation)
  A = modeltransformation.A
  b = modeltransformation.b
  [A[1, 1], A[1, 2], A[1, 3], b[1], A[2, 1], A[2, 2], A[2, 3], b[2], A[3, 1], A[3, 2], A[3, 3], b[3], 0, 0, 0, 1]
end

struct Metadata
  geokeydirectory::GeoKeyDirectory
  geodoubleparams::Union{GeoDoubleParams,Nothing}
  geoasciiparams::Union{GeoAsciiParams,Nothing}
  modelpixelscale::Union{ModelPixelScale,Nothing}
  modeltiepoint::Union{ModelTiepoint,Nothing}
  modeltransformation::Union{ModelTransformation,Nothing}
end

function Metadata(;
  geokeydirectory=GeoKeyDirectory(),
  geodoubleparams=nothing,
  geoasciiparams=nothing,
  modelpixelscale=nothing,
  modeltiepoint=nothing,
  modeltransformation=ModelTransformation()
)
  haspixelscale = !isnothing(modelpixelscale)
  hastiepoint = !isnothing(modeltiepoint)
  hastransformation = !isnothing(modeltransformation)
  if (haspixelscale || hastiepoint) && !(haspixelscale && hastiepoint)
    throw(ArgumentError("ModelPixelScale and ModelTiepoint must be defined together"))
  end
  if !haspixelscale && !hastransformation
    throw(ArgumentError("GeoTIFF requires a ModelPixelScale with ModelTiepoint or a ModelTransformation"))
  end
  if haspixelscale && hastransformation
    throw(ArgumentError("only one of ModelPixelScale with ModelTiepoint or ModelTransformation can be defined"))
  end
  Metadata(geokeydirectory, geodoubleparams, geoasciiparams, modelpixelscale, modeltiepoint, modeltransformation)
end

function metadata(;
  version=1,
  revision=1,
  minor=1,
  pixelscale=nothing,
  tiepoint=nothing,
  transformation=isnothing(pixelscale) && isnothing(tiepoint) ? (_A, _b) : nothing,
  rastertype=nothing,
  modeltype=nothing,
  projectedcrs=nothing,
  geodeticcrs=nothing,
  verticalcrs=nothing,
  citation=nothing,
  geodeticcitation=nothing,
  projectedcitation=nothing,
  verticalcitation=nothing,
  geogangularunits=nothing,
  geogazimuthunits=nothing,
  geoglinearunits=nothing,
  projlinearunits=nothing,
  verticalunits=nothing,
  geogangularunitsize=nothing,
  geoglinearunitsize=nothing,
  projlinearunitsize=nothing,
  geodeticdatum=nothing,
  primemeridian=nothing,
  primemeridianlongitude=nothing,
  ellipsoid=nothing,
  ellipsoidsemimajoraxis=nothing,
  ellipsoidsemiminoraxis=nothing,
  ellipsoidinvflattening=nothing,
  verticaldatum=nothing,
  projection=nothing,
  projmethod=nothing,
  projstdparallel1=nothing,
  projstdparallel2=nothing,
  projnatoriginlong=nothing,
  projnatoriginlat=nothing,
  projfalseoriginlong=nothing,
  projfalseoriginlat=nothing,
  projcenterlong=nothing,
  projcenterlat=nothing,
  projstraightvertpolelong=nothing,
  projazimuthangle=nothing,
  projfalseeasting=nothing,
  projfalsenorthing=nothing,
  projfalseorigineasting=nothing,
  projfalseoriginnorthing=nothing,
  projcentereasting=nothing,
  projcenternorthing=nothing,
  projscaleatnatorigin=nothing,
  projscaleatcenter=nothing
)
  geokeys = GeoKey[]
  doubleparams = Float64[]
  asciiparams = String[]

  geokeyshort!(key, value) = !isnothing(value) && push!(geokeys, GeoKey(key, 0, 1, value))

  function geokeydouble!(key, value)
    if !isnothing(value)
      offset = length(doubleparams)
      push!(geokeys, GeoKey(key, GeoDoubleParamsTag, 1, offset))
      push!(doubleparams, value)
    end
  end

  function geokeyascii!(key, value)
    if !isnothing(value)
      str = value * "|" # terminator
      offset = sum(length, asciiparams, init=0)
      push!(geokeys, GeoKey(key, GeoAsciiParamsTag, length(str), offset))
      push!(asciiparams, str)
    end
  end

  # GeoTIFF Configuration GeoKeys
  geokeyshort!(GTRasterTypeGeoKey, rastertype)
  geokeyshort!(GTModelTypeGeoKey, modeltype)

  # Model CRS
  geokeyshort!(ProjectedCRSGeoKey, projectedcrs)
  geokeyshort!(GeodeticCRSGeoKey, geodeticcrs)
  geokeyshort!(VerticalGeoKey, verticalcrs)

  # Citation GeoKeys
  geokeyascii!(GTCitationGeoKey, citation)
  geokeyascii!(GeodeticCitationGeoKey, geodeticcitation)
  geokeyascii!(ProjectedCitationGeoKey, projectedcitation)
  geokeyascii!(VerticalCitationGeoKey, verticalcitation)

  # User defined Model CRS

  # Units GeoKeys
  geokeyshort!(GeogAngularUnitsGeoKey, geogangularunits)
  geokeyshort!(GeogAzimuthUnitsGeoKey, geogazimuthunits)
  geokeyshort!(GeogLinearUnitsGeoKey, geoglinearunits)
  geokeyshort!(ProjLinearUnitsGeoKey, projlinearunits)
  geokeyshort!(VerticalUnitsGeoKey, verticalunits)
  # Unit Size GeoKeys
  geokeydouble!(GeogAngularUnitSizeGeoKey, geogangularunitsize)
  geokeydouble!(GeogLinearUnitSizeGeoKey, geoglinearunitsize)
  geokeydouble!(ProjLinearUnitSizeGeoKey, projlinearunitsize)

  # Geodetic Datum
  geokeyshort!(GeodeticDatumGeoKey, geodeticdatum)
  # PrimeMeridian
  geokeyshort!(PrimeMeridianGeoKey, primemeridian)
  geokeydouble!(PrimeMeridianLongitudeGeoKey, primemeridianlongitude)
  # Ellipsoid
  geokeyshort!(EllipsoidGeoKey, ellipsoid)
  geokeydouble!(EllipsoidSemiMajorAxisGeoKey, ellipsoidsemimajoraxis)
  geokeydouble!(EllipsoidSemiMinorAxisGeoKey, ellipsoidsemiminoraxis)
  geokeydouble!(EllipsoidInvFlatteningGeoKey, ellipsoidinvflattening)

  # Vertical Datum
  geokeyshort!(VerticalDatumGeoKey, verticaldatum)

  # Map Projection
  geokeyshort!(ProjectionGeoKey, projection)
  geokeyshort!(ProjMethodGeoKey, projmethod)
  # Map Projection parameters
  # Angular parameters
  geokeydouble!(ProjStdParallel1GeoKey, projstdparallel1)
  geokeydouble!(ProjStdParallel2GeoKey, projstdparallel2)
  geokeydouble!(ProjNatOriginLongGeoKey, projnatoriginlong)
  geokeydouble!(ProjNatOriginLatGeoKey, projnatoriginlat)
  geokeydouble!(ProjFalseOriginLongGeoKey, projfalseoriginlong)
  geokeydouble!(ProjFalseOriginLatGeoKey, projfalseoriginlat)
  geokeydouble!(ProjCenterLongGeoKey, projcenterlong)
  geokeydouble!(ProjCenterLatGeoKey, projcenterlat)
  geokeydouble!(ProjStraightVertPoleLongGeoKey, projstraightvertpolelong)
  # Azimuth angle
  geokeydouble!(ProjAzimuthAngleGeoKey, projazimuthangle)
  # Linear parameters
  geokeydouble!(ProjFalseEastingGeoKey, projfalseeasting)
  geokeydouble!(ProjFalseNorthingGeoKey, projfalsenorthing)
  geokeydouble!(ProjFalseOriginEastingGeoKey, projfalseorigineasting)
  geokeydouble!(ProjFalseOriginNorthingGeoKey, projfalseoriginnorthing)
  geokeydouble!(ProjCenterEastingGeoKey, projcentereasting)
  geokeydouble!(ProjCenterNorthingGeoKey, projcenternorthing)
  # Scalar parameters
  geokeydouble!(ProjScaleAtNatOriginGeoKey, projscaleatnatorigin)
  geokeydouble!(ProjScaleAtCenterGeoKey, projscaleatcenter)

  geokeydirectory = GeoKeyDirectory(; version, revision, minor, geokeys)

  geodoubleparams = isempty(doubleparams) ? nothing : GeoDoubleParams(doubleparams)

  geoasciiparams = isempty(asciiparams) ? nothing : GeoAsciiParams(join(asciiparams))

  modelpixelscale = if isnothing(pixelscale)
    nothing
  else
    x, y, z = pixelscale
    ModelPixelScale(; x, y, z)
  end

  modeltiepoint = if isnothing(tiepoint)
    nothing
  else
    i, j, k, x, y, z = tiepoint
    ModelTiepoint(; i, j, k, x, y, z)
  end

  modeltransformation = if isnothing(transformation)
    nothing
  else
    A, b = transformation
    ModelTransformation(; A, b)
  end

  Metadata(; geokeydirectory, geodoubleparams, geoasciiparams, modelpixelscale, modeltiepoint, modeltransformation)
end

# --------
# HELPERS
# --------

const _A = [
  1.0 0.0 0.0
  0.0 1.0 0.0
  0.0 0.0 1.0
]

const _b = [0.0, 0.0, 0.0]
