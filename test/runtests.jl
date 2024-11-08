using GeoTIFF
using TiffImages
using ColorTypes
using FixedPointNumbers
using Test

datadir = joinpath(@__DIR__, "data")
savedir = mktempdir()

@testset "GeoTIFF.jl" begin
  # default affine parameters
  A = [
    1.0 0.0 0.0
    0.0 1.0 0.0
    0.0 0.0 1.0
  ]
  b = [0.0, 0.0, 0.0]

  @testset "load" begin
    # tiff files without metadata
    geotiff = GeoTIFF.load(joinpath(datadir, "test.tif"))
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: RGB
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams3D(metadata) == (A, b)

    geotiff = GeoTIFF.load(joinpath(datadir, "test_gray.tif"))
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: Gray
    @test isnothing(GeoTIFF.rastertype(metadata))
    @test isnothing(GeoTIFF.modeltype(metadata))
    @test isnothing(GeoTIFF.epsgcode(metadata))
    @test GeoTIFF.affineparams3D(metadata) == (A, b)

    # tiff files with metadata
    geotiff = GeoTIFF.load(joinpath(datadir, "utm.tif"))
    metadata = GeoTIFF.metadata(geotiff)
    @test eltype(geotiff) <: RGB
    @test GeoTIFF.rastertype(metadata) == GeoTIFF.PixelIsArea
    @test GeoTIFF.modeltype(metadata) == GeoTIFF.Projected2D
    @test GeoTIFF.epsgcode(metadata) == 32617
    @test GeoTIFF.affineparams2D(metadata) ==
          ([121.52985600000001 0.0; 0.0 -164.762688], [688258.223819, 4.555765966137e6])
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
    @test GeoTIFF.affineparams3D(metadata) == (A, b)

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
    @test GeoTIFF.affineparams3D(metadata) == (A, b)

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
    @test GeoTIFF.affineparams3D(metadata) == (A, b)
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
    @test GeoTIFF.affineparams3D(metadata) == (A, b)

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
    @test GeoTIFF.affineparams3D(metadata) == (A, b)
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
    @test GeoTIFF.affineparams3D(metadata) == (A, b)

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
    @test GeoTIFF.affineparams3D(metadata) == (A, b)
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
    @test GeoTIFF.affineparams3D(metadata) == (A, b)
  end
end
