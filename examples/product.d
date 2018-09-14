import std.datetime.stopwatch : benchmark;
import std.math : approxEqual;
import std.random : uniform01;
import std.stdio : writefln;

import cl = dcltk;
import derelict.opencl.cl : cl_event;

void main() {
    // matrix size.
    enum {
        ROWS = 100,
        COLS = 200,
        RESULT_COLS = 300
    }

    // initialize operand matrixes.
    auto lhs = new float[ROWS * COLS];
    foreach(ref e; lhs) {
        e = uniform01!float;
    }
    auto rhs = new float[COLS * RESULT_COLS];
    foreach(ref e; rhs) {
        e = uniform01!float;
    }
    auto cpuResult = new float[ROWS * RESULT_COLS];
    auto gpuResult = new float[ROWS * RESULT_COLS];

    // benchmark CPU and GPU.
    immutable cpuMsecs = benchmark!(() => productCpu(
                lhs, rhs, cpuResult, ROWS, COLS, RESULT_COLS))(1)[0].total!"msecs";
    immutable gpuMsecs = benchmark!(() => productGpu(
                lhs, rhs, gpuResult, ROWS, COLS, RESULT_COLS))(1)[0].total!"msecs";
    writefln("cpu: %d msecs, gpu: %d msecs", cpuMsecs, gpuMsecs);

    //writefln("%s", cpuResult);
    //writefln("%s", gpuResult);

    // check result values.
    foreach(i, e; cpuResult) {
        assert(approxEqual(e, gpuResult[i]));
    }
}

/// matrix product by CPU.
void productCpu(
        const(float)[] lhs,
        const(float)[] rhs,
        float[] result,
        uint rows,
        uint cols,
        uint resultCols)
in {
    assert(lhs.length == rows * cols);
    assert(rhs.length == cols * resultCols);
    assert(result.length == rows * resultCols);
} body {
    for(size_t i = 0; i < rows; ++i) {
        for(size_t j = 0; j < resultCols; ++j) {
            float value = 0.0f;
            for(size_t k = 0; k < cols; ++k) {
                value += lhs[i * rows + k] * rhs[k * resultCols + j];
            }
            result[i * resultCols + j] = value;
        }
    }
}

/// matrix product by GPU.
void productGpu(
        const(float)[] lhsArray,
        const(float)[] rhsArray,
        float[] resultArray,
        uint rows,
        uint cols,
        uint resultCols)
in {
    assert(lhsArray.length == rows * cols);
    assert(rhsArray.length == cols * resultCols);
    assert(resultArray.length == rows * resultCols);
} body {
    auto platformId = cl.loadOpenCl();
    writefln("loaded: %s %s %s(%s) %s [%s]",
        cl.getPlatformProfile(platformId),
        cl.getPlatformName(platformId),
        cl.getPlatformVersion(platformId),
        cl.getPlatformCLVersion(platformId),
        cl.getPlatformVendor(platformId),
        cl.getPlatformExtensions(platformId));

    auto context = cl.createDefaultContext(platformId);
    scope(exit) cl.releaseContext(context);
    auto deviceIds = cl.getContextDeviceIds(context);
    if(deviceIds.length <= 0) {
        throw new cl.OpenClException("device not found.");
    }

    auto device = deviceIds[0];
    writefln("device: %s %s gmem: %d, lmem: %d, cu: %d, w: %d, dim: %d %s",
        cl.getDeviceName(device),
        cl.getDeviceVersion(device),
        cl.getDeviceGlobalMemorySize(device),
        cl.getDeviceLocalMemorySize(device),
        cl.getDeviceMaxComputeUnits(device),
        cl.getDeviceMaxWorkGroupSize(device),
        cl.getDeviceMaxWorkItemDimensions(device),
        cl.getDeviceMaxWorkItemSizes(device));
    if(!cl.isGpuDevice(device)) {
        writefln("WARNING: device is not GPU!");
    }

    auto commandQueue = cl.createCommandQueue(context, device);
    scope(exit) cl.releaseCommandQueue(commandQueue);

    auto program = cl.createProgramFromSource(context, `
        __kernel void product(
                __global const float *lhs,
                __global const float *rhs,
                __global float *result,
                uint rows,
                uint cols,
                uint resultCols) {
            const size_t groupIndex = get_global_id(0);
            const size_t groupSize = get_global_size(0);

            for(size_t i = groupIndex; i < rows; i += groupSize) {
                for(size_t j = 0; j < resultCols; ++j) {
                    float value = 0.0f;
                    for(size_t k = 0; k < cols; ++k) {
                        value += lhs[i * rows + k] * rhs[k * resultCols + j];
                    }
                    result[i * resultCols + j] = value;
                }
            }
        }
    `);
    scope(exit) cl.releaseProgram(program);
    cl.buildProgram(program, deviceIds);

    auto kernel = cl.createKernel(program, "product");
    scope(exit) cl.releaseKernel(kernel);

    auto lhs = cl.createReadBuffer(context, lhsArray);
    scope(exit) cl.releaseBuffer(lhs);
    auto rhs = cl.createReadBuffer(context, rhsArray);
    scope(exit) cl.releaseBuffer(rhs);
    auto result = cl.createWriteBuffer(context, resultArray.length * float.sizeof);
    scope(exit) cl.releaseBuffer(result);

    // set kernel arguments.
    cl.setKernelArg(kernel, 0, lhs);
    cl.setKernelArg(kernel, 1, rhs);
    cl.setKernelArg(kernel, 2, result);
    cl.setKernelArg(kernel, 3, rows);
    cl.setKernelArg(kernel, 4, cols);
    cl.setKernelArg(kernel, 5, resultCols);

    cl_event event;
    cl.enqueueKernel(commandQueue, kernel, [13], [1]);
    cl.enqueueReadBuffer(commandQueue, result, 0, resultArray, event);
    cl.flushCommandQueue(commandQueue);

    cl.waitAndReleaseEvents(event);
    cl.finishCommandQueue(commandQueue);
}

