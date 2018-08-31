module dcltk;

import derelict.opencl.cl;

import std.conv : to;
import std.exception : assumeUnique;

/**
 *  OpenCL exception.
 */
class OpenClException : Exception {

    /**
     *  construct by message.
     *
     *  Params:
     *      msg = error message.
     *      file = file name.
     *      line = source line number.
     *      nextInChain = exception chain.
     */
    pure nothrow @nogc @safe this(
            string msg,
            string file = __FILE__,
            size_t line = __LINE__,
            Throwable nextInChain = null) {
        super(msg, file, line, nextInChain);
    }
}

/**
 *  enforce success OpenCL API.
 *
 *  Params:
 *      result = OpenCL API result.
 *      file = source file name.
 *      line = source line number.
 *  Throws:
 *      OpenClException
 */
T enforceCl(T)(T result, string file = __FILE__, size_t line = __LINE__) @safe if(is(T : cl_int)) {
    if(result != CL_SUCCESS) {
        throw new OpenClException(openClErrorCodeToMessage(result), file, line);
    }
    return result;
}

/**
 *  load OpenCL libraries.
 */
void loadOpenCl() {
    DerelictCL.load();
    //DerelictCL.reload();
    //DerelictCL.loadEXT();
}

/**
 *  get available platform ids.
 *
 *  Returns:
 *      available platform ids.
 */
cl_platform_id[] getPlatformIds() {
    cl_uint count = 0;
    enforceCl(clGetPlatformIDs(0, null, &count));

    auto result = new cl_platform_id[count];
    enforceCl(clGetPlatformIDs(count, result.ptr, &count));
    return result[0 .. count];
}

/**
 *  get platform information.
 *
 *  Params:
 *      platformId = platform ID.
 *      name = information name.
 *  Returns:
 *      platform inforamtion.
 */
string getPlatformInfo(cl_platform_id platformId, cl_platform_info name) {
    size_t size = 0;
    enforceCl(clGetPlatformInfo(platformId, name, 0, null, &size));

    auto result = new char[size];
    enforceCl(clGetPlatformInfo(platformId, name, size, result.ptr, &size));
    return assumeUnique(result[0 .. size]);
}

/// get platform profile
string getPlatformProfile(cl_platform_id platformId) {
    return getPlatformInfo(platformId, CL_PLATFORM_PROFILE);
}

/// get platform version
string getPlatformVersion(cl_platform_id platformId) {
    return getPlatformInfo(platformId, CL_PLATFORM_VERSION);
}

/// get platform name
string getPlatformName(cl_platform_id platformId) {
    return getPlatformInfo(platformId, CL_PLATFORM_NAME);
}

/// get platform vendor
string getPlatformVendor(cl_platform_id platformId) {
    return getPlatformInfo(platformId, CL_PLATFORM_VENDOR);
}

/// get platform extensions
string getPlatformExtensions(cl_platform_id platformId) {
    return getPlatformInfo(platformId, CL_PLATFORM_EXTENSIONS);
}

/**
 *  OpenCL error code to message string.
 *
 *  Params:
 *      errorCode = OpenCL error code.
 *  Returns:
 *      error code message.
 */
string openClErrorCodeToMessage(cl_int errorCode) @safe {
    switch(errorCode) {
    case CL_SUCCESS: return "CL_SUCCESS";
    case CL_DEVICE_NOT_FOUND: return "CL_DEVICE_NOT_FOUND";
    case CL_DEVICE_NOT_AVAILABLE: return "CL_DEVICE_NOT_AVAILABLE";
    case CL_COMPILER_NOT_AVAILABLE: return "CL_COMPILER_NOT_AVAILABLE";
    case CL_MEM_OBJECT_ALLOCATION_FAILURE: return "CL_MEM_OBJECT_ALLOCATION_FAILURE";
    case CL_OUT_OF_RESOURCES: return "CL_OUT_OF_RESOURCES";
    case CL_OUT_OF_HOST_MEMORY: return "CL_OUT_OF_HOST_MEMORY";
    case CL_PROFILING_INFO_NOT_AVAILABLE: return "CL_PROFILING_INFO_NOT_AVAILABLE";
    case CL_MEM_COPY_OVERLAP: return "CL_MEM_COPY_OVERLAP";
    case CL_IMAGE_FORMAT_MISMATCH: return "CL_IMAGE_FORMAT_MISMATCH";
    case CL_IMAGE_FORMAT_NOT_SUPPORTED: return "CL_IMAGE_FORMAT_NOT_SUPPORTED";
    case CL_BUILD_PROGRAM_FAILURE: return "CL_BUILD_PROGRAM_FAILURE";
    case CL_MAP_FAILURE: return "CL_MAP_FAILURE";
    case CL_MISALIGNED_SUB_BUFFER_OFFSET: return "CL_MISALIGNED_SUB_BUFFER_OFFSET";
    case CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST: return "CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST";
    case CL_COMPILE_PROGRAM_FAILURE: return "CL_COMPILE_PROGRAM_FAILURE";
    case CL_LINKER_NOT_AVAILABLE: return "CL_LINKER_NOT_AVAILABLE";
    case CL_LINK_PROGRAM_FAILURE: return "CL_LINK_PROGRAM_FAILURE";
    case CL_DEVICE_PARTITION_FAILED: return "CL_DEVICE_PARTITION_FAILED";
    case CL_KERNEL_ARG_INFO_NOT_AVAILABLE: return "CL_KERNEL_ARG_INFO_NOT_AVAILABLE";
    case CL_INVALID_VALUE: return "CL_INVALID_VALUE";
    case CL_INVALID_DEVICE_TYPE: return "CL_INVALID_DEVICE_TYPE";
    case CL_INVALID_PLATFORM: return "CL_INVALID_PLATFORM";
    case CL_INVALID_DEVICE: return "CL_INVALID_DEVICE";
    case CL_INVALID_CONTEXT: return "CL_INVALID_CONTEXT";
    case CL_INVALID_QUEUE_PROPERTIES: return "CL_INVALID_QUEUE_PROPERTIES";
    case CL_INVALID_COMMAND_QUEUE: return "CL_INVALID_COMMAND_QUEUE";
    case CL_INVALID_HOST_PTR: return "CL_INVALID_HOST_PTR";
    case CL_INVALID_MEM_OBJECT: return "CL_INVALID_MEM_OBJECT";
    case CL_INVALID_IMAGE_FORMAT_DESCRIPTOR: return "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR";
    case CL_INVALID_IMAGE_SIZE: return "CL_INVALID_IMAGE_SIZE";
    case CL_INVALID_SAMPLER: return "CL_INVALID_SAMPLER";
    case CL_INVALID_BINARY: return "CL_INVALID_BINARY";
    case CL_INVALID_BUILD_OPTIONS: return "CL_INVALID_BUILD_OPTIONS";
    case CL_INVALID_PROGRAM: return "CL_INVALID_PROGRAM";
    case CL_INVALID_PROGRAM_EXECUTABLE: return "CL_INVALID_PROGRAM_EXECUTABLE";
    case CL_INVALID_KERNEL_NAME: return "CL_INVALID_KERNEL_NAME";
    case CL_INVALID_KERNEL_DEFINITION: return "CL_INVALID_KERNEL_DEFINITION";
    case CL_INVALID_KERNEL: return "CL_INVALID_KERNEL";
    case CL_INVALID_ARG_INDEX: return "CL_INVALID_ARG_INDEX";
    case CL_INVALID_ARG_VALUE: return "CL_INVALID_ARG_VALUE";
    case CL_INVALID_ARG_SIZE: return "CL_INVALID_ARG_SIZE";
    case CL_INVALID_KERNEL_ARGS: return "CL_INVALID_KERNEL_ARGS";
    case CL_INVALID_WORK_DIMENSION: return "CL_INVALID_WORK_DIMENSION";
    case CL_INVALID_WORK_GROUP_SIZE: return "CL_INVALID_WORK_GROUP_SIZE";
    case CL_INVALID_WORK_ITEM_SIZE: return "CL_INVALID_WORK_ITEM_SIZE";
    case CL_INVALID_GLOBAL_OFFSET: return "CL_INVALID_GLOBAL_OFFSET";
    case CL_INVALID_EVENT_WAIT_LIST: return "CL_INVALID_EVENT_WAIT_LIST";
    case CL_INVALID_EVENT: return "CL_INVALID_EVENT";
    case CL_INVALID_OPERATION: return "CL_INVALID_OPERATION";
    case CL_INVALID_GL_OBJECT: return "CL_INVALID_GL_OBJECT";
    case CL_INVALID_BUFFER_SIZE: return "CL_INVALID_BUFFER_SIZE";
    case CL_INVALID_MIP_LEVEL: return "CL_INVALID_MIP_LEVEL";
    case CL_INVALID_GLOBAL_WORK_SIZE: return "CL_INVALID_GLOBAL_WORK_SIZE";
    case CL_INVALID_PROPERTY: return "CL_INVALID_PROPERTY";
    case CL_INVALID_IMAGE_DESCRIPTOR: return "CL_INVALID_IMAGE_DESCRIPTOR";
    case CL_INVALID_COMPILER_OPTIONS: return "CL_INVALID_COMPILER_OPTIONS";
    case CL_INVALID_LINKER_OPTIONS: return "CL_INVALID_LINKER_OPTIONS";
    case CL_INVALID_DEVICE_PARTITION_COUNT: return "CL_INVALID_DEVICE_PARTITION_COUNT";
    case CL_INVALID_PIPE_SIZE: return "CL_INVALID_PIPE_SIZE";
    case CL_INVALID_DEVICE_QUEUE: return "CL_INVALID_DEVICE_QUEUE";
    case CL_INVALID_SPEC_ID: return "CL_INVALID_SPEC_ID";
    case CL_MAX_SIZE_RESTRICTION_EXCEEDED: return "CL_MAX_SIZE_RESTRICTION_EXCEEDED";
    default:
        return "OpenCL Error: " ~ errorCode.to!string;
    }
}

