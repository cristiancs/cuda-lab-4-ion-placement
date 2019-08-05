#include <iostream>
#include <fstream>
#include <string>
#include <stdio.h>
#include <stdlib.h>
using namespace std;
#include <iterator>
#include <algorithm>
#include <random>
#include <math.h>

// Cada thread deberia calcular la carga de 1 punto
__global__ void calcular_carga(float* iones_x, float* iones_y, float* cargas, int cantidad) {
    int tId = threadIdx.x + blockIdx.x * blockDim.x;
    
	if(tId < 8192*8192) {
        
        int x = tId/8192;
        int y = tId%8192;
        
        float carga = 0;
        float distancia;
        float x_2, y_2;
        carga = 0;
        for (int i = 0; i < cantidad; i++)  {
            x_2 = (x - iones_x[i]) * (x - iones_x[i]);
            y_2 = (y - iones_y[i]) * (y - iones_y[i]);
            distancia = sqrt(x_2 + y_2);
            if (distancia == 0)  {
                distancia = 0.0000000000001;
            }
            carga += 1.0 / distancia;
        }
    
        cargas[tId] = carga;
    }
    
}

// cada thread calcula la menor carga en su fila y la guarda

__global__ void calcular_carga_fila(float* iones_x, float* iones_y, float* cargas, float*cargas_menores, int cantidad) {
    int tId = threadIdx.x + blockIdx.x * blockDim.x;
    

    if(tId < 8192) {
        float Q_menor = 100000000000;
        int x = tId;
        int y;
        

        for (int i = tId*8192; i < tId*8192+8192; i++)  {
            if(cargas[i] <Q_menor){
                Q_menor = cargas[i];
                y = i%8192;
            }
        }
        cargas_menores[tId*3] = Q_menor;
        cargas_menores[tId*3+1] = x;
        cargas_menores[tId*3+2] = y;
    }
    
}
// Calculamos entre todas la menor y ponemos la carga ahí
__global__ void posicionar_ion(float* iones_x, float* iones_y, float*cargas_menores, int cantidad) {
    int tId = threadIdx.x + blockIdx.x * blockDim.x;
    float Q_menor = 100000000000;
    int a;
    int b;

    if(tId < 1) {
        for (int i = 0; i < 8192*3; i+=3)  {
            if(cargas_menores[i] < Q_menor){
                printf("%i %f \n", i, Q_menor);
                Q_menor = cargas_menores[i];
                
                a = cargas_menores[i+1];
                b = cargas_menores[i+2];
                
            }
        }
        iones_x[cantidad] = a;
        iones_y[cantidad] = b; 
    }

    
    
}



int main(int argc, char const *argv[])
{
    
    float *gpu_cargas, *cargas_menores, *cargas, *gpu_iones_x, *gpu_iones_y, *iones_x, *iones_y;
    cudaEvent_t ct1, ct2;
    float dt;
    int cantidad;
    iones_x = new float[6000];
    iones_y = new float[6000];
    cargas = new float[8192*8192];

    int block_size = 256;
    int grid_size = (int) ceil( (float) 8192*8182 / block_size);
    int grid_size_b = (int) ceil( (float) 8192 / block_size);
    int grid_size_c = (int) ceil( (float) 1 / block_size);

    
    FILE *in = fopen("dataset", "r");
    for (int i = 0; i < 5000; i++)
    {
        fscanf(in, "%f %f", &iones_x[i], &iones_y[i]);
        //cout << iones_x[i] << " " << iones_y[i] << endl;
    }


    cudaMalloc(&gpu_iones_x, sizeof(float) * 6000);
    cudaMalloc(&gpu_iones_y, sizeof(float) * 6000);
    cudaMalloc(&gpu_cargas, sizeof(float) * 8192 * 8192);
    cudaMalloc(&cargas_menores, sizeof(float) * 8192*3);

    cudaMemcpy(gpu_cargas, cargas, sizeof(float) * 8192 * 8192, cudaMemcpyHostToDevice);
    

    cudaEventCreate(&ct1);
	cudaEventCreate(&ct2);
    cudaEventRecord(ct1);

    
    for (cantidad = 5000; cantidad < 5100; cantidad++)
    {
        cudaMemcpy(gpu_iones_x, iones_x, sizeof(float) * 6000, cudaMemcpyHostToDevice);
        cudaMemcpy(gpu_iones_y, iones_y, sizeof(float) * 6000, cudaMemcpyHostToDevice);
        calcular_carga<<<grid_size, block_size>>>(gpu_iones_x, gpu_iones_y, gpu_cargas, cantidad);
        cudaDeviceSynchronize();

        

        cudaDeviceSynchronize();
        //cout << "Calculando carga fila para " <<  cantidad << endl;
        calcular_carga_fila<<<grid_size_b, block_size>>>(gpu_iones_x, gpu_iones_y, gpu_cargas, cargas_menores, cantidad);
        cudaDeviceSynchronize();
        //cout << "Posicionado ion para " <<  cantidad << endl;
        posicionar_ion<<<grid_size_c, block_size>>>(gpu_iones_x, gpu_iones_y, cargas_menores, cantidad);
        cudaDeviceSynchronize();
        cudaMemcpy(iones_x, gpu_iones_x,sizeof(float) * 6000, cudaMemcpyDeviceToHost);
        cudaMemcpy(iones_y, gpu_iones_y,sizeof(float) * 6000, cudaMemcpyDeviceToHost);
        cout << iones_x[cantidad] << " " << iones_y[cantidad] << endl;
    }

    cudaEventRecord(ct2);
	cudaEventSynchronize(ct2);
    cudaEventElapsedTime(&dt, ct1, ct2);

    cout << "Tiempo: " << dt << "[ms]" << '\n';

    cudaFree(gpu_iones_x);
    cudaFree(gpu_iones_y);
    cudaFree(cargas);
    cudaFree(cargas_menores);

    delete iones_x;
    delete iones_y;
    
    return 0;
}