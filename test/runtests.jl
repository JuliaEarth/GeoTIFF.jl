using GeoTIFF
using TiffImages
using ColorTypes
using FixedPointNumbers
using Test

datadir = joinpath(@__DIR__, "data")
savedir = mktempdir()

@testset "GeoTIFF.jl" begin
  # default affine parameters
  A2D = [
    1.0 0.0
    0.0 1.0
  ]
  b2D = [0.0, 0.0]

  A3D = [
    1.0 0.0 0.0
    0.0 1.0 0.0
    0.0 0.0 1.0
  ]
  b3D = [0.0, 0.0, 0.0]

  @testset "load" begin
    # tiff files without metadata
    geotiff = GeoTIFF.load(joinpath(datadir, "test.tif"))
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: RGB
    @test size(geotiff) == (100, 100)
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)

    geotiff = GeoTIFF.load(joinpath(datadir, "test_gray.tif"))
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: Gray
    @test size(geotiff) == (108, 108)
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)

    # tiff files with metadata
    geotiff = GeoTIFF.load(joinpath(datadir, "utm.tif"))
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: RGB
    @test size(geotiff) == (100, 100)
    @test GeoTIFF.rastertype(metadata) == GeoTIFF.PixelIsArea
    @test GeoTIFF.modeltype(metadata) == GeoTIFF.Projected2D
    @test GeoTIFF.epsgcode(metadata) == 32617
    A = [121.52985600000001 0.0; 0.0 -164.762688]
    b = [688258.223819, 4.555765966137e6]
    @test GeoTIFF.affineparams2D(metadata) == (A, b)

    # GeoTIFF permutes the image by default
    geotiff = GeoTIFF.load(joinpath(datadir, "natural_earth_1.tif"))
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: RGB
    @test size(geotiff) == (162, 81)
    @test size(geotiff) == reverse(size(GeoTIFF.tiff(geotiff)))
    @test GeoTIFF.rastertype(metadata) == GeoTIFF.PixelIsArea
    @test GeoTIFF.modeltype(metadata) == GeoTIFF.Geographic2D
    @test GeoTIFF.epsgcode(metadata) == 4326
    A = [2.222222222222001 0.0; 0.0 -2.222222222222001]
    b = [-180.0, 90.0]
    @test GeoTIFF.affineparams2D(metadata) == (A, b)
  end

  @testset "GeoTIFFImage" begin
    geotiff = GeoTIFF.load(joinpath(datadir, "test.tif"))
    @test geotiff isa GeoTIFF.GeoTIFFImage
    # getters
    @test GeoTIFF.tiff(geotiff) isa TiffImages.AbstractTIFF
    @test GeoTIFF.metadata(geotiff) isa GeoTIFF.Metadata
    # abstract array interface
    @test size(geotiff) == (100, 100)
    @test eltype(geotiff) <: RGB
    @test typeof(geotiff[1, 1]) <: RGB
    color = RGB(1.0, 0.0, 0.0)
    geotiff[1, 1] = color
    @test geotiff[1, 1] == color
    @test IndexStyle(geotiff) === IndexCartesian()

    # multi-channel image
    file = joinpath(savedir, "multi.tiff")
    channel1 = rand(10, 10)
    channel2 = rand(10, 10)
    channel3 = rand(10, 10)
    channel4 = rand(10, 10)
    GeoTIFF.save(file, channel1, channel2, channel3, channel4)
    geotiff = GeoTIFF.load(file)
    @test eltype(geotiff) <: TiffImages.WidePixel
    @test GeoTIFF.nchannels(geotiff) == 4
    @test GeoTIFF.channel(geotiff, 1) == channel1
    @test GeoTIFF.channel(geotiff, 2) == channel2
    @test GeoTIFF.channel(geotiff, 3) == channel3
    @test GeoTIFF.channel(geotiff, 4) == channel4
  end

  @testset "save" begin
    # saving geotiffs
    file1 = joinpath(datadir, "test.tif")
    file2 = joinpath(savedir, "test.tif")
    geotiff1 = GeoTIFF.load(file1)
    GeoTIFF.save(file2, geotiff1)
    geotiff2 = GeoTIFF.load(file2)
    metadata1 = GeoTIFF.metadata(geotiff1)
    metadata2 = GeoTIFF.metadata(geotiff2)
    @test eltype(geotiff2) === eltype(geotiff1)
    @test GeoTIFF.rastertype(metadata2) === GeoTIFF.rastertype(metadata1)
    @test GeoTIFF.modeltype(metadata2) === GeoTIFF.modeltype(metadata1)
    @test GeoTIFF.epsgcode(metadata2) === GeoTIFF.epsgcode(metadata1)
    @test GeoTIFF.affineparams3D(metadata2) === GeoTIFF.affineparams3D(metadata1)

    file1 = joinpath(datadir, "test_gray.tif")
    file2 = joinpath(savedir, "test_gray.tif")
    geotiff1 = GeoTIFF.load(file1)
    GeoTIFF.save(file2, geotiff1)
    geotiff2 = GeoTIFF.load(file2)
    metadata1 = GeoTIFF.metadata(geotiff1)
    metadata2 = GeoTIFF.metadata(geotiff2)
    @test eltype(geotiff2) === eltype(geotiff1)
    @test GeoTIFF.rastertype(metadata2) === GeoTIFF.rastertype(metadata1)
    @test GeoTIFF.modeltype(metadata2) === GeoTIFF.modeltype(metadata1)
    @test GeoTIFF.epsgcode(metadata2) === GeoTIFF.epsgcode(metadata1)
    @test GeoTIFF.affineparams3D(metadata2) === GeoTIFF.affineparams3D(metadata1)

    file1 = joinpath(datadir, "utm.tif")
    file2 = joinpath(savedir, "utm.tif")
    geotiff1 = GeoTIFF.load(file1)
    GeoTIFF.save(file2, geotiff1)
    geotiff2 = GeoTIFF.load(file2)
    metadata1 = GeoTIFF.metadata(geotiff1)
    metadata2 = GeoTIFF.metadata(geotiff2)
    @test eltype(geotiff2) === eltype(geotiff1)
    @test GeoTIFF.rastertype(metadata2) === GeoTIFF.rastertype(metadata1)
    @test GeoTIFF.modeltype(metadata2) === GeoTIFF.modeltype(metadata1)
    @test GeoTIFF.epsgcode(metadata2) === GeoTIFF.epsgcode(metadata1)
    @test GeoTIFF.affineparams2D(metadata2) === GeoTIFF.affineparams2D(metadata1)

    # tiff files
    file = joinpath(savedir, "tiff_file.tiff")
    tiff = TiffImages.load(joinpath(datadir, "test.tif"))
    GeoTIFF.save(file, tiff)
    geotiff = GeoTIFF.load(file)
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: RGB
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)

    # array of colors
    file = joinpath(savedir, "array.tiff")
    array = rand(Gray{Float64}, 10, 10)
    GeoTIFF.save(file, array)
    geotiff = GeoTIFF.load(file)
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: Gray
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)

    # channel arrays
    # float
    # single channel
    file = joinpath(savedir, "float_single.tiff")
    channel = rand(10, 10)
    GeoTIFF.save(file, channel)
    geotiff = GeoTIFF.load(file)
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: Gray
    @test eltype(geotiff[1, 1]) <: Float64
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)
    # multiple channels
    file = joinpath(savedir, "float_multi.tiff")
    channel1 = rand(10, 10)
    channel2 = rand(10, 10)
    channel3 = rand(10, 10)
    channel4 = rand(10, 10)
    GeoTIFF.save(file, channel1, channel2, channel3, channel4)
    geotiff = GeoTIFF.load(file)
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: TiffImages.WidePixel
    @test eltype(TiffImages.color(geotiff[1, 1])) <: Float64
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)

    # int
    # single channel
    file = joinpath(savedir, "int_single.tiff")
    channel = rand(1:10, 10, 10)
    GeoTIFF.save(file, channel)
    geotiff = GeoTIFF.load(file)
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: Gray
    @test eltype(geotiff[1, 1]) <: FixedPoint
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)
    # multiple channels
    file = joinpath(savedir, "int_multi.tiff")
    channel1 = rand(1:10, 10, 10)
    channel2 = rand(1:10, 10, 10)
    channel3 = rand(1:10, 10, 10)
    channel4 = rand(1:10, 10, 10)
    GeoTIFF.save(file, channel1, channel2, channel3, channel4)
    geotiff = GeoTIFF.load(file)
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: TiffImages.WidePixel
    @test eltype(TiffImages.color(geotiff[1, 1])) <: FixedPoint
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)

    # uint
    # single channel
    file = joinpath(savedir, "uint_single.tiff")
    channel = rand(UInt(1):UInt(10), 10, 10)
    GeoTIFF.save(file, channel)
    geotiff = GeoTIFF.load(file)
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: Gray
    @test eltype(geotiff[1, 1]) <: FixedPoint
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)
    # multiple channels
    file = joinpath(savedir, "uint_multi.tiff")
    channel1 = rand(UInt(1):UInt(10), 10, 10)
    channel2 = rand(UInt(1):UInt(10), 10, 10)
    channel3 = rand(UInt(1):UInt(10), 10, 10)
    channel4 = rand(UInt(1):UInt(10), 10, 10)
    GeoTIFF.save(file, channel1, channel2, channel3, channel4)
    geotiff = GeoTIFF.load(file)
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: TiffImages.WidePixel
    @test eltype(TiffImages.color(geotiff[1, 1])) <: FixedPoint
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)
  end

  @testset "metadata" begin
    # default
    metadata = GeoTIFF.metadata()
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)

    # transformation
    θ = π / 4
    A = [cos(θ) -sin(θ); sin(θ) cos(θ)]
    b = [10.0, 50.0]
    metadata = GeoTIFF.metadata(transformation=(A, b))
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A, b)

    # tiepoint and pixelscale
    metadata = GeoTIFF.metadata(tiepoint=(0.0, 0.0, 0.0, 0.0, 0.0, 0.0), pixelscale=(1.0, -1.0, 1.0))
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams2D(metadata) == (A2D, b2D)
    @test GeoTIFF.affineparams3D(metadata) == (A3D, b3D)

    # EPSG CRS
    # WGS 84: https://epsg.io/4326
    metadata = GeoTIFF.metadata(rastertype=GeoTIFF.PixelIsArea, modeltype=GeoTIFF.Geographic2D, geodeticcrs=4326)
    @test GeoTIFF.rastertype(metadata) == GeoTIFF.PixelIsArea
    @test GeoTIFF.modeltype(metadata) == GeoTIFF.Geographic2D
    @test GeoTIFF.epsgcode(metadata) == 4326

    # Web Mercator: https://epsg.io/3857
    metadata = GeoTIFF.metadata(rastertype=GeoTIFF.PixelIsArea, modeltype=GeoTIFF.Projected2D, projectedcrs=3857)
    @test GeoTIFF.rastertype(metadata) == GeoTIFF.PixelIsArea
    @test GeoTIFF.modeltype(metadata) == GeoTIFF.Projected2D
    @test GeoTIFF.epsgcode(metadata) == 3857

    # citation
    metadata = GeoTIFF.metadata(
      rastertype=GeoTIFF.PixelIsArea,
      modeltype=GeoTIFF.Geographic2D,
      geodeticcrs=4326,
      citation="Test citation"
    )
    @test GeoTIFF.rastertype(metadata) == GeoTIFF.PixelIsArea
    @test GeoTIFF.modeltype(metadata) == GeoTIFF.Geographic2D
    @test GeoTIFF.epsgcode(metadata) == 4326
    @test GeoTIFF.geokeyascii(metadata, GeoTIFF.GTCitationGeoKey) == "Test citation"

    # user defined CRS
    metadata = GeoTIFF.metadata(
      rastertype=GeoTIFF.PixelIsArea,
      modeltype=GeoTIFF.Projected2D,
      projectedcrs=GeoTIFF.UserDefined,
      geodeticcrs=4326, # WGS 84: https://epsg.io/4326
      citation="Test citation",
      projectedcitation="TransverseMercator",
      projlinearunits=9001, # EPSG meters: https://epsg.org/unit_9001/metre.html
      projection=GeoTIFF.UserDefined,
      projmethod=1, # GeoTIFF Transverse Mercator: https://docs.ogc.org/is/19-008r4/19-008r4.html#_map_projection_methods
      projscaleatnatorigin=0.9996, # scale factor
      projnatoriginlat=15.0, # latitude of origin
      projnatoriginlong=25.0 # longitude of origin
    )
    @test GeoTIFF.rastertype(metadata) == GeoTIFF.PixelIsArea
    @test GeoTIFF.modeltype(metadata) == GeoTIFF.Projected2D
    @test GeoTIFF.geokeyvalue(metadata, GeoTIFF.ProjectedCRSGeoKey) == GeoTIFF.UserDefined
    @test GeoTIFF.geokeyvalue(metadata, GeoTIFF.GeodeticCRSGeoKey) == 4326
    @test GeoTIFF.geokeyascii(metadata, GeoTIFF.GTCitationGeoKey) == "Test citation"
    @test GeoTIFF.geokeyascii(metadata, GeoTIFF.ProjectedCitationGeoKey) == "TransverseMercator"
    @test GeoTIFF.geokeyvalue(metadata, GeoTIFF.ProjLinearUnitsGeoKey) == 9001
    @test GeoTIFF.geokeyvalue(metadata, GeoTIFF.ProjectionGeoKey) == GeoTIFF.UserDefined
    @test GeoTIFF.geokeyvalue(metadata, GeoTIFF.ProjMethodGeoKey) == 1
    @test GeoTIFF.geokeydouble(metadata, GeoTIFF.ProjScaleAtNatOriginGeoKey) == 0.9996
    @test GeoTIFF.geokeydouble(metadata, GeoTIFF.ProjNatOriginLatGeoKey) == 15.0
    @test GeoTIFF.geokeydouble(metadata, GeoTIFF.ProjNatOriginLongGeoKey) == 25.0
  end
end
