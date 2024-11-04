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

@enum GeoKeyID::UInt16 begin
  GTRasterTypeGeoKey = 1025
  GTModelTypeGeoKey = 1024
  ProjectedCRSGeoKey = 3072
  GeodeticCRSGeoKey = 2048
  VerticalGeoKey = 4096
  GTCitationGeoKey = 1026
  GeodeticCitationGeoKey = 2049
  ProjectedCitationGeoKey = 3073
  VerticalCitationGeoKey = 4097
  GeogAngularUnitsGeoKey = 2054
  GeogAzimuthUnitsGeoKey = 2060
  GeogLinearUnitsGeoKey = 2052
  ProjLinearUnitsGeoKey = 3076
  VerticalUnitsGeoKey = 4099
  GeogAngularUnitSizeGeoKey = 2055
  GeogLinearUnitSizeGeoKey = 2053
  ProjLinearUnitSizeGeoKey = 3077
  GeodeticDatumGeoKey = 2050
  PrimeMeridianGeoKey = 2051
  PrimeMeridianLongitudeGeoKey = 2061
  EllipsoidGeoKey = 2056
  EllipsoidSemiMajorAxisGeoKey = 2057
  EllipsoidSemiMinorAxisGeoKey = 2058
  EllipsoidInvFlatteningGeoKey = 2059
  VerticalDatumGeoKey = 4098
  ProjectionGeoKey = 3074
  ProjMethodGeoKey = 3075
  ProjStdParallel1GeoKey = 3078
  ProjStdParallel2GeoKey = 3079
  ProjNatOriginLongGeoKey = 3080
  ProjNatOriginLatGeoKey = 3081
  ProjFalseOriginLongGeoKey = 3084
  ProjFalseOriginLatGeoKey = 3085
  ProjCenterLongGeoKey = 3088
  ProjCenterLatGeoKey = 3089
  ProjStraightVertPoleLongGeoKey = 3095
  ProjAzimuthAngleGeoKey = 3094
  ProjFalseEastingGeoKey = 3082
  ProjFalseNorthingGeoKey = 3083
  ProjFalseOriginEastingGeoKey = 3086
  ProjFalseOriginNorthingGeoKey = 3087
  ProjCenterEastingGeoKey = 3090
  ProjCenterNorthingGeoKey = 3091
  ProjScaleAtNatOriginGeoKey = 3092
  ProjScaleAtCenterGeoKey = 3093
end

# Corresponding names in the GeoTIFF specification:
# id - KeyID
# tag - TIFFTagLocation
# count - Count
# value - ValueOffset
struct GeoKey
  id::GeoKeyID
  tag::UInt16
  count::UInt16
  value::UInt16
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
  geokeyvalues = @view params[5:end]
  geokeys = map(Iterators.partition(geokeyvalues, 4)) do geokey
    id = GeoKeyID(geokey[1])
    tag = geokey[2]
    count = geokey[3]
    value = geokey[4]
    GeoKey(id, tag, count, value)
  end

  version = params[1]
  revision = params[2]
  minor = params[3]
  nkeys = params[4]
  GeoKeyDirectory(version, revision, minor, nkeys, geokeys)
end

function params(geokeydir::GeoKeyDirectory)
  params = [geokeydir.version, geokeydir.revision, geokeydir.minor, geokeydir.nkeys]
  for geokey in geokeydir.geokeys
    append!(params, [UInt16(geokey.id), geokey.tag, geokey.count, geokey.value])
  end
  params
end

struct GeoDoubleParams
  params::Vector{Float64}
end

params(geodouble::GeoDoubleParams) = geodouble.params

struct GeoAsciiParams
  params::String
end

params(geoascii::GeoAsciiParams) = geoascii.params

struct ModelPixelScale
  x::Float64
  y::Float64
  z::Float64
end

ModelPixelScale(; x=1.0, y=1.0, z=1.0) = ModelPixelScale(x, y, z)

ModelPixelScale(params::Vector{Float64}) = ModelPixelScale(params[1], params[2], params[3])

params(scale::ModelPixelScale) = [scale.x, scale.y, scale.z]

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

params(tiepoint::ModelTiepoint) = [tiepoint.i, tiepoint.j, tiepoint.k, tiepoint.x, tiepoint.y, tiepoint.z]

struct ModelTransformation
  A::Matrix{Float64}
  b::Vector{Float64}
end

function ModelTransformation(; A=[1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0], b=[0.0, 0.0, 0.0])
  sz = size(A)
  if !allequal(sz)
    throw(ArgumentError("`A` must be a square matrix"))
  end
  dim = first(sz)
  if dim ∉ (2, 3)
    throw(ArgumentError("only 2D and 3D transformations are supported"))
  end
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

function params(transform::ModelTransformation)
  A = transform.A
  b = transform.b
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

Metadata(;
  geokeydirectory=GeoKeyDirectory(),
  geodoubleparams=nothing,
  geoasciiparams=nothing,
  modelpixelscale=nothing,
  modeltiepoint=nothing,
  modeltransformation=ModelTransformation()
) = Metadata(geokeydirectory, geodoubleparams, geoasciiparams, modelpixelscale, modeltiepoint, modeltransformation)
