# -----------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# -----------------------------------------------------------------

"""
    GeoTIFF.GeoTag

Enum of all tags supported by GeoTIFF.

See [Requirements Class TIFF](https://docs.ogc.org/is/19-008r4/19-008r4.html#_requirements_class_tiff)
section of the GeoTIFF Spec for more details.
"""
@enum GeoTag::UInt16 begin
  GeoKeyDirectoryTag = 34735
  GeoDoubleParamsTag = 34736
  GeoAsciiParamsTag = 34737
  ModelPixelScaleTag = 33550
  ModelTiepointTag = 33922
  ModelTransformationTag = 34264
end

"""
    GeoTIFF.GeoKeyDirectory(; version=1, revision=1, minor=1, geokeys=GeoKey[])

The GeoKeyDirectory stores the GeoKeys and the format version.

Corresponding field names in the GeoTIFF specification:
* `version`: KeyDirectoryVersion
* `revision`: KeyRevision
* `minor`: MinorRevision
* `nkeys`: NumberOfKeys
* `geokeys`: Key Entry Set

See [Requirements Class GeoKeyDirectoryTag](https://docs.ogc.org/is/19-008r4/19-008r4.html#_requirements_class_geokeydirectorytag)
section of the GeoTIFF specification for a explanation of each field.
"""
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
    id = GeoKeyID(params[1 + i])
    tag = params[2 + i]
    count = params[3 + i]
    value = params[4 + i]
    GeoKey(id, tag, count, value)
  end

  version = params[1]
  revision = params[2]
  minor = params[3]
  GeoKeyDirectory(version, revision, minor, nkeys, geokeys)
end

function params(geokeydirectory::GeoKeyDirectory)
  params = [geokeydirectory.version, geokeydirectory.revision, geokeydirectory.minor, geokeydirectory.nkeys]
  # Requirement 1.6 (https://docs.ogc.org/is/19-008r4/19-008r4.html#_requirements_class_tiff)
  # the GeoKeys must be written with the IDs sorted in ascending order
  geokeys = sort(geokeydirectory.geokeys, by=(gk -> gk.id))
  for geokey in geokeys
    append!(params, [UInt16(geokey.id), geokey.tag, geokey.count, geokey.value])
  end
  params
end

"""
    GeoTIFF.GeoDoubleParams(params)

The GeoDoubleParams stores the double (Float64) parameters of the GeoKeys.

See [Requirements Class GeoDoubleParamsTag](https://docs.ogc.org/is/19-008r4/19-008r4.html#_requirements_class_geodoubleparamstag)
section of the GeoTIFF specification for more details.
"""
struct GeoDoubleParams
  params::Vector{Float64}
end

params(geodoubleparams::GeoDoubleParams) = geodoubleparams.params

"""
    GeoTIFF.GeoAsciiParams(params)

The GeoAsciiParams stores the ASCII string parameters of the GeoKeys.

See [Requirements Class GeoAsciiParamsTag](https://docs.ogc.org/is/19-008r4/19-008r4.html#_requirements_class_geoasciiparamstag)
section of the GeoTIFF specification for more details.
"""
struct GeoAsciiParams
  params::String
end

params(geoasciiparams::GeoAsciiParams) = geoasciiparams.params

"""
    GeoTIFF.ModelPixelScale(; x=1.0, y=-1.0, z=1.0)

The ModelPixelScale contains the scale parameters of the raster-to-model transformation.

See [Raster to Model Coordinate Transformation Requirements](https://docs.ogc.org/is/19-008r4/19-008r4.html#_raster_to_model_coordinate_transformation_requirements)
section of the GeoTIFF specification for more details.
"""
struct ModelPixelScale
  x::Float64
  y::Float64
  z::Float64
end

ModelPixelScale(; x=1.0, y=-1.0, z=1.0) = ModelPixelScale(x, y, z)

ModelPixelScale(params::Vector{Float64}) = ModelPixelScale(params[1], params[2], params[3])

params(modelpixelscale::ModelPixelScale) = [modelpixelscale.x, modelpixelscale.y, modelpixelscale.z]

"""
    GeoTIFF.ModelTiepoint(; i=0.0, j=0.0, k=0.0, x=0.0, y=0.0, z=0.0)

The ModelTiepoint contains the tie point parameters of the raster-to-model transformation.

See [Raster to Model Coordinate Transformation Requirements](https://docs.ogc.org/is/19-008r4/19-008r4.html#_raster_to_model_coordinate_transformation_requirements)
section of the GeoTIFF specification for more details.
"""
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

"""
    GeoTIFF.ModelTransformation(; A=[1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0], b=[0.0, 0.0, 0.0])

The ModelTransformation contains the affine parameters of the raster-to-model transformation.

For convinience, the 4x4 transformation matrix of the ModelTransformation, is splited into `A` and `b`.

See [Raster to Model Coordinate Transformation Requirements](https://docs.ogc.org/is/19-008r4/19-008r4.html#_raster_to_model_coordinate_transformation_requirements)
section of the GeoTIFF specification for more details.
"""
struct ModelTransformation
  A::SMatrix{3,3,Float64,9}
  b::SVector{3,Float64}
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
    SA[A[1, 1] A[1, 2] 0; A[2, 1] A[2, 2] 0; 0 0 0], SA[b[1], b[2], 0]
  elseif dim == 3
    SMatrix{3,3}(A), SVector{3}(b)
  else
    throw(ArgumentError("only 2D and 3D transformations are supported"))
  end
  ModelTransformation(A′, b′)
end

function ModelTransformation(params::Vector{Float64})
  A = SA[
    params[1] params[2] params[3]
    params[5] params[6] params[7]
    params[9] params[10] params[11]
  ]
  b = SA[params[4], params[8], params[12]]
  ModelTransformation(A, b)
end

function params(modeltransformation::ModelTransformation)
  A = modeltransformation.A
  b = modeltransformation.b
  [A[1, 1], A[1, 2], A[1, 3], b[1], A[2, 1], A[2, 2], A[2, 3], b[2], A[3, 1], A[3, 2], A[3, 3], b[3], 0, 0, 0, 1]
end

"""
    GeoTIFF.Metadata(;
      geokeydirectory=GeoKeyDirectory(),
      geodoubleparams=nothing,
      geoasciiparams=nothing,
      modelpixelscale=nothing,
      modeltiepoint=nothing,
      modeltransformation=ModelTransformation()
    )

Stores all GeoTIFF format metadata.

Corresponding field names in the GeoTIFF specification:
* `geokeydirectory`: GeoKeyDirectoryTag
* `geodoubleparams`: GeoDoubleParamsTag
* `geoasciiparams`: GeoAsciiParamsTag
* `modeltiepoint`: ModelPixelScaleTag
* `modeltiepoint`: ModelTiepointTag
* `modeltransformation`: ModelTransformationTag

See [Requirements Class TIFF](https://docs.ogc.org/is/19-008r4/19-008r4.html#_requirements_class_tiff)
section of the GeoTIFF specification for more details.

### Notes

* Construct metadata manually is hard work. See the [`GeoTIFF.metadata`](@ref) function
  for a more user-friendly way to construct metadata.
"""
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

"""
    GeoTIFF.metadata(; [parameters...])

Construct a GeoTIFF metadata with parameter values.

# Parameters

## GeoTIFF version
* `version` (integer): KeyDirectoryVersion of the GeoTIFF (default to `1`);
* `revision` (integer): KeyRevision of the GeoTIFF (default to `1`);
* `minor` (integer): MinorRevision of the GeoTIFF (default to `1`);
  * `0`: GeoTIFF 1.0 version;
  * `1`: GeoTIFF 1.1 version;

## Raster to Model transformation
* `pixelscale` (3-tuple of float): `(x, y, z)` pixel scale parameters;
  * Must be set together with `tiepoint`;
* `tiepoint` (6-tuple of float): `(i, j, k, x, y, z)` tiepoint parameters;
* `transformation` (matrix of float, vector of float): `(A, b)` affine parameters (default to `A` as identity matrix and `b` as vector of zeros
  if no transformation is passed);
  * Should not be set if `pixelscale` and `tiepoint` have been set;

All parameters in the following sections can receive the values
`GeoTIFF.Undefined` and `GeoTIFF.UserDefined` in addition to the allowed values, 
except the string and float parameters.

## GeoTIFF Configuration
* `rastertype` (`GeoTIFF.PixelIsArea` | `GeoTIFF.PixelIsPoint`): raster type of the GeoTIFF;
* `modeltype` (`GeoTIFF.Projected2D` | `GeoTIFF.Geographic2D` | `GeoTIFF.Geocentric3D`): model type of the GeoTIFF;
  * If `GeoTIFF.Projected2D`, then `projectcrs` must be set;
  * If `GeoTIFF.Geographic2D` or `GeoTIFF.Geocentric3D`, then `geodeticcrs` must be set;

## Model CRS
* `projectcrs` (1024-32766): EPSG code of the Projected CRS;
  * If `GeoTIFF.UserDefined`, then `projectedcitation`, `geodeticcrs` and `projection` must be set;
* `geodeticcrs` (1024-32766): EPSG code of the Geographic or Geocentric CRS;
  * If `GeoTIFF.UserDefined`, then `geodeticcitation`, `geodeticdatum` and `geogangularunits` (for Geographic CRS) 
  or `geoglinearunits` (for Geocentric CRS) must be set;
* `verticalcrs` (1024-32766): EPSG code of the Vertical CRS;
  * If `GeoTIFF.UserDefined`, then `verticalcitation`, `verticaldatum` and `verticalunits` must be set;

## Citation
* `citation` (string): Description of the GeoTIFF file;
* `geodeticcitation` (string): Description of the Geodetic CRS;
* `projectedcitation` (string): Description of the Projected CRS;
* `verticalcitation` (string): Description of the Vertical CRS;

## User Defined CRS
### Units
* `geogangularunits` (1024-32766): EPSG code of angular unit for the:
  * user defined Geographic CRS;
  * user defined prime meridians;
  * user defined projection parameters that are angles;
    * If `GeoTIFF.UserDefined`, then `geodeticcitation` and `geogangularunitsize` must be set;
* `geogazimuthunits` (1024-32766): EPSG code of angular unit for the user defined projection parameters
  when these differ from the angular unit of `geogangularunits`;
  * If `GeoTIFF.UserDefined`, then `geodeticcitation` and `geogangularunitsize` must be set;
* `geoglinearunits` (1024-32766): EPSG code of length unit for the:
  * user defined Geocentric CRS;
  * height of user defined Geographic 3D CRS;
  * user defined ellipsoid axes;
    * If `GeoTIFF.UserDefined`, then `geodeticcitation` and `geoglinearunitsize` must be set;
* `projlinearunits` (1024-32766): EPSG code of length unit for the:
  * user defined Projected CRS;
  * user defined projection parameters that are lengths;
    * If `GeoTIFF.UserDefined`, then `projectedcitation` and `projlinearunitsize` must be set;
* `verticalunits` (1024-32766): EPSG code of length unit for the user defined Vertical CRS;
  * `GeoTIFF.UserDefined` is not supported;

### Unit size
* `geogangularunitsize` (float): Size of user defined Geographic angle with radian as base unit;
* `geoglinearunitsize` (float): Size of user defined Geographic length with meter as base unit;
* `projlinearunitsize` (float): Size of user defined Projected length with meter as base unit;

### Geodetic Datum
* `geodeticdatum` (1024-32766): EPSG code of Datum for the user defined Geographic CRS;
  * If `GeoTIFF.UserDefined`, then `geodeticcitation`, `primemeridian` and `ellipsoid` must be set;
* `primemeridian` (1024-32766): EPSG code of Prime Meridian for the user defined Datum;
  * If `GeoTIFF.UserDefined`, then `primemeridianlongitude` must be set;
* `primemeridianlongitude` (float): Longitude angle relative to the international reference meridian
  for the user defined Prime Meridian;
* `ellipsoid` (1024-32766): EPSG code of Ellipsoid for the user defined Datum;
  * If `GeoTIFF.UserDefined`, then `ellipsoidsemimajoraxis` and `ellipsoidsemiminoraxis` or `ellipsoidinvflattening` must be set;
* `ellipsoidsemimajoraxis` (float): Semi-major axis of the user defined Ellipsoid;
* `ellipsoidsemiminoraxis` (float): Semi-minor axis of the user defined Ellipsoid;
* `ellipsoidinvflattening` (float): Inverse flattening of the user defined Ellipsoid;

### Vertical Datum
* `verticaldatum` (1024-32766): EPSG code of Datum for the user defined Vertical CRS;
  * If `GeoTIFF.UserDefined`, then `verticalcitation` must be set;

### Projection
* `projection` (1024-32766): EPSG code of coordinate operation for the user defined Projected CRS;
  * If `GeoTIFF.UserDefined`, then `projectedcitation`, `projmethod`, and `projlinearunits` must be set;
* `projmethod` (1-27): GeoTIFF projection code of the user defined projection;
  * See [Map Projection methods](https://docs.ogc.org/is/19-008r4/19-008r4.html#_map_projection_methods)
    for the full list of codes;
  * All projection parameters of the passed projection method must be set;

### Projection parameters
* `projstdparallel1` (float): First standard parallel;
* `projstdparallel2` (float): Second standard parallel;
* `projnatoriginlong` (float): Longitude of natural origin;
* `projnatoriginlat` (float): Latitude of natural origin;
* `projfalseoriginlong` (float): Longitude of false origin;
* `projfalseoriginlat` (float): Latitude of false origin;
* `projcenterlong` (float): Longitude of projection center;
* `projcenterlat` (float): Latitude of projection center;
* `projstraightvertpolelong` (float): Longitude of straight vertical pole;
* `projazimuthangle` (float): Azimuth angle east of true north of the central line passing through the projection center; 
* `projfalseeasting` (float): False easting;
* `projfalsenorthing` (float): False northing;
* `projfalseorigineasting` (float): Easting coordinate of false origin;
* `projfalseoriginnorthing` (float): Northing coordinate of false origin;
* `projcentereasting` (float): Easting coordinate of projection center;
* `projcenternorthing` (float): Northing coordinate of projection center;
* `projscaleatnatorigin` (float): Scale of natural origin;
* `projscaleatcenter` (float): Scale of projection center;

See [Requirements](https://docs.ogc.org/is/19-008r4/19-008r4.html#_requirements)
section of the GeoTIFF specification for more details.
"""
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
      push!(geokeys, GeoKey(key, UInt16(GeoDoubleParamsTag), 1, offset))
      push!(doubleparams, value)
    end
  end

  function geokeyascii!(key, value)
    if !isnothing(value)
      str = value * "|" # terminator
      offset = sum(length, asciiparams, init=0)
      push!(geokeys, GeoKey(key, UInt16(GeoAsciiParamsTag), length(str), offset))
      push!(asciiparams, str)
    end
  end

  # GeoTIFF Configuration
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

const _A = SA[
  1.0 0.0 0.0
  0.0 1.0 0.0
  0.0 0.0 1.0
]

const _b = SA[0.0, 0.0, 0.0]
