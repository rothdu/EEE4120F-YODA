#define CL_TARGET_OPENCL_VERSION 300

#ifndef BITWIDTH
#define BITWIDTH 32
#endif

#ifndef DATALENGTH
#define DATALENGTH 10
#endif

#include <stdio.h>
#include <CL/cl.h>
#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <sstream>

using namespace std;

int main(void)
{

    clock_t start, end, start_queue, end_queue; // Timers

    // uint8_t key = 0xB4352B93;
    // uint16_t key = 0xB4352B93;
    uint key = 0xB4352B93;

    // uint8_t* data = new uint8_t[DATALENGTH];
    // uint16_t* data = new uint16_t[DATALENGTH];
    uint *data = new uint[DATALENGTH];

    // uint8_t *output = new uint8_t[DATALENGTH];
    // uint16_t *output = new uint16_t[DATALENGTH];
    uint *output = new uint[DATALENGTH];

    string filename = "../data/rotating-xor.csv";

    ifstream file(filename);

    if (!file.is_open())
    {
        std::cerr << "Error opening file: " << filename << std::endl;
        return 1;
    }

    std::string line;
    int count = 0;
    std::getline(file, line);

    while (std::getline(file, line))
    {
        std::stringstream ss(line);
        std::string cell;

        // Get the first cell
        if (std::getline(ss, cell, ','))
        {
            // Convert hex string to int
            uint value;
            std::stringstream hex_stream;
            hex_stream << std::hex << cell;
            hex_stream >> value;
            data[count] = value;
            count++;
        }
    }

    // for (size_t i = 0; i < DATALENGTH; i++)
    // {
    //     cout << std::hex << data[i] << "  " << dec << (i) << endl;
    // }

    file.close();

    start = clock();

    cl_mem data_buffer, key_buffer, output_buffer;

    cl_uint platformCount; // keeps track of the number of platforms you have installed on your device
    cl_platform_id *platforms;
    // get platform count
    clGetPlatformIDs(5, NULL, &platformCount); // sets platformCount to the number of platforms

    // get all platforms
    platforms = (cl_platform_id *)malloc(sizeof(cl_platform_id) * platformCount);
    clGetPlatformIDs(platformCount, platforms, NULL); // saves a list of platforms in the platforms variable

    cl_platform_id platform = platforms[0]; // Select the platform you would like to use in this program (change index to do this). If you would like to see all available platforms run platform.cpp.

// #ifndef DATA_ONLY
//     // Outputs the information of the chosen platform
//     char *Info = (char *)malloc(0x1000 * sizeof(char));
//     clGetPlatformInfo(platform, CL_PLATFORM_NAME, 0x1000, Info, 0);
//     printf("Name      : %s\n", Info);
//     clGetPlatformInfo(platform, CL_PLATFORM_VENDOR, 0x1000, Info, 0);
//     printf("Vendor    : %s\n", Info);
//     clGetPlatformInfo(platform, CL_PLATFORM_VERSION, 0x1000, Info, 0);
//     printf("Version   : %s\n", Info);
//     clGetPlatformInfo(platform, CL_PLATFORM_PROFILE, 0x1000, Info, 0);
//     printf("Profile   : %s\n", Info);
// #endif

    cl_device_id device; // this is your deviceID
    cl_int err;

    // Access a device
    // The if statement checks to see if the chosen platform uses a GPU, if not it setups the device using the CPU
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);
    if (err == CL_DEVICE_NOT_FOUND)
    {
        err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_CPU, 1, &device, NULL);
    }
// #ifndef DATA_ONLY
//     printf("Device ID = %i\n", err);
// #endif

    cl_context context; // This is your contextID, the line below must just run
    context = clCreateContext(NULL, 1, &device, NULL, NULL, NULL);

    FILE *program_handle;
    program_handle = fopen("Kernel.cl", "r");

    // get program size
    size_t program_size; //, log_size;
    fseek(program_handle, 0, SEEK_END);
    program_size = ftell(program_handle);
    rewind(program_handle);

    // sort buffer out
    char *program_buffer; //, *program_log;
    program_buffer = (char *)malloc(program_size + 1);
    program_buffer[program_size] = '\0';
    fread(program_buffer, sizeof(char), program_size, program_handle);
    fclose(program_handle);

    cl_program program = clCreateProgramWithSource(context, 1, (const char **)&program_buffer, &program_size, NULL); // this compiles the kernels code

    cl_int err3 = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
#ifndef DATA_ONLY
    printf("program ID = %i\n", err3);
#endif

#ifndef ADVANCED
    cl_kernel kernel = clCreateKernel(program, "Encryption", &err);
#else
    cl_kernel kernel = clCreateKernel(program, "EncryptionAdvanced", &err);
#endif

    // enabling event profiling for the queue
    cl_queue_properties queue_properties[] = {CL_QUEUE_PROPERTIES, CL_QUEUE_PROFILING_ENABLE, 0};
    cl_command_queue queue = clCreateCommandQueueWithProperties(context, device, queue_properties, NULL);

    //------------------------------------------------------------------------

    size_t global_size = DATALENGTH;

    data_buffer = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, DATALENGTH * BITWIDTH / 8, data, &err);

    key_buffer = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR, BITWIDTH / 8, &key, &err);

    output_buffer = clCreateBuffer(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR, DATALENGTH * BITWIDTH / 8, output, &err);

    clSetKernelArg(kernel, 0, sizeof(cl_mem), &data_buffer);
    clSetKernelArg(kernel, 1, sizeof(cl_mem), &key_buffer);
    clSetKernelArg(kernel, 2, sizeof(cl_mem), &output_buffer);

    // event for profiling (timing)
    cl_event event;
    cl_int err4;

    // letting OpenCL decide the workgroup size or manual selection
    // start running clock
    start_queue = clock();
    err4 = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &global_size, NULL, 0, NULL, &event);

    err = clEnqueueReadBuffer(queue, output_buffer, CL_TRUE, 0, BITWIDTH / 8 * DATALENGTH, output, 0, NULL, &event);

    // Wait for the kernel to finish execution
    clWaitForEvents(1, &event);

    // This command stops the program here until everything in the queue has been run
    clFinish(queue);

    // total time from enqueueing kernel to reading back the output
    end_queue = clock();

    // Get the execution time of the kernel
    cl_ulong submit_time, start_time, end_time;

    // submit is when the CPU first sends the queue, start is when the first kernel begins processing and end is when the GPU has completed its final kernel
    clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_SUBMIT, sizeof(cl_ulong), &submit_time, NULL);
    clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_START, sizeof(cl_ulong), &start_time, NULL);
    clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_END, sizeof(cl_ulong), &end_time, NULL);

    // Convert nanoseconds to seconds
    double overhead_time = (double)(start_time - submit_time) * 1.0e-9;
    double execution_time = (double)(end_time - start_time) * 1.0e-9;
    double O_E = (double)(end_time - submit_time) * 1.0e-9;
    double queue_CPU_time = (double)(end_queue - start_queue) / CLOCKS_PER_SEC;
    cout << endl;
    for (size_t i = 0; i < DATALENGTH; i++)
    {
        cout << std::hex << output[i] << "  ";
    }
    cout << endl;
    delete[] data, output;
    clReleaseKernel(kernel);
    clReleaseMemObject(data_buffer);
    clReleaseMemObject(key_buffer);
    clReleaseMemObject(output_buffer);
    clReleaseCommandQueue(queue);
    clReleaseProgram(program);
    clReleaseContext(context);

    // total CPU time from kernel structures to releasing resources
    end = clock();
    double total_CPU_time = (double)(end - start) / CLOCKS_PER_SEC;

// various display options
#ifndef DATA_ONLY
    printf("\nOverhead time:\t\t%.9f seconds\n", overhead_time);

    printf("Execution time:\t\t%.9f seconds\n", execution_time);

    // printf("Overhead + Execution time: %f seconds\n", overhead_time + execution_time);
    printf("O+E time:\t\t%.9f seconds\n", O_E);

    printf("Queue CPU Time:\t\t%.9f seconds \n", queue_CPU_time);

    printf("\nTotal CPU Time:\t\t%.9f seconds \n", total_CPU_time);

    printf("\nKernel check:\t\t%i \n", err4);
#endif

    return 0;
}