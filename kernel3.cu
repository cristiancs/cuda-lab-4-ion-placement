#include <iostream>
#include <fstream>
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iterator>
#include <algorithm>
#include <random>
#include <math.h>
using namespace std;

struct Ion 
{ 
    float x, y;
};

void poblar(Ion iones[]) {
   
    FILE *in = fopen("dataset", "r");
    for (int i = 0; i < 5000; i++)
    {
        fscanf(in, "%f %f", &iones[i].x, &iones[i.y]);
       // cout << iones[i] << " " << iones[6000+i] << endl;
    }

    fclose(in);


    //sort(iones, iones + 5000, ionCompare);
}

__host__ __device__ float distanciaEuclidiana(Ion a, int x, int y) {
    float d = sqrtf(powf(a.x - x, 2) + powf(a.y - y, 2));
    return d > 0.0 ? d : 1.0; // evitar división por 0
}

__global__ void calcular_carga(Ion ion, float* cargas, int cantidad, int tIdO) {
    int tId = threadIdx.x + blockIdx.x * blockDim.x;
    int tIdC = tIdO + tId;
    
    if(tId < 200 * 200 && tIdC >= 0 && tIdC < 8192 * 8192) {
        int signo_x = (tId / (200) < 100) * (-1) + (tId / (200) >= 100) * (1);
        int signo_y = (tId % (200) < 100) * (1) + (tId % (200) >= 100) * (-1);

        int a = (tId / 200) * signo_x;
        int b = (tId % 200) * signo_y;

        int valido_x = !(ion.x + a < 0 || ion.x + a > 8192) * 1; 
        int valido_y = !(ion.y + b < 0 || ion.y + b > 8192) * 1; 

        float dist = distanciaEuclidiana(ion, a, b);
        atomicAdd(&cargas[tIdC], valido_x * valido_y * (dist <= 100.0) * (1.0 / dist));
        //if(cargas[tIdC] > 0.0)
        //    printf("%f ", cargas[tIdC]);
    }
}

__global__ void vertices_cercanos(Ion iones[], float* cargas, int cantidad) {
    int tId = threadIdx.x + blockIdx.x * blockDim.x;
    
    if(tId < cantidad) {
        int block_size = 256;
        int grid_size = (int) ceil( (float) 200 * 200 / block_size);
        calcular_carga<<<grid_size, block_size>>>(iones[tId], cargas, cantidad, tId);
    }
}

__global__ void posicionar_ion(Ion iones[], float* cargas, int cantidad) {
    int tId = threadIdx.x + blockIdx.x * blockDim.x;
    float Q_menor = 100000000000;
    int a;
    int b;

    if(tId < 1) {
        for (int i = 0; i < 8192*3; i+=3)  {
            if(cargas[i] < Q_menor){
                Q_menor = cargas[i];
                a = cargas[i+1];
                b = cargas[i+2];
            }
        }
        iones[cantidad].x = a;
        iones[cantidad].y = b; 
    }
}

int main(int argc, char const *argv[])
{
    Ion iones[6000];
    poblar(iones);

    Ion *gpu_iones; 
    float *cargas;

    cudaEvent_t ct1, ct2;
    float dt;
    int cantidad;

    cudaMalloc(&gpu_iones, sizeof(Ion) * 6000);
    cudaMalloc(&cargas, sizeof(float*) * 8192 * 8192);
    cudaMemcpy(gpu_iones, iones, sizeof(Ion) * 6000, cudaMemcpyHostToDevice);
 
    cudaEventCreate(&ct1);
	cudaEventCreate(&ct2);
    cudaEventRecord(ct1);
   
    for (cantidad = 5000; cantidad < 5009; cantidad++)
    {
        int block_size = 256;
        int grid_size = (int) ceil( (float) cantidad / block_size);

        cout << "Calculando carga para " <<  cantidad << endl;
        vertices_cercanos<<<grid_size, block_size>>>(gpu_iones, cargas, cantidad);
        cudaDeviceSynchronize();
        
        grid_size = (int) ceil( (float) 1 / block_size);
        posicionar_ion<<<grid_size, block_size>>>(iones, cargas, cantidad);
        cudaDeviceSynchronize();

        cudaMemcpy(iones, gpu_iones,sizeof(Ion) * 6000, cudaMemcpyDeviceToHost);
        cout << iones[cantidad].x << " " << iones[cantidad].y << endl;
    }

    cudaEventRecord(ct2);
	cudaEventSynchronize(ct2);
    cudaEventElapsedTime(&dt, ct1, ct2);

    cout << "Tiempo: " << dt << "[ms]" << '\n';

    cudaFree(gpu_iones);
    
    return 0;
}

// Aquí yacen los restos de la grandiosa idea de ordenar los puntos y encontrar los que pertenecen a la circunferencia con búsqueda binaria

/*
__host__ __device__ int busquedaBinaria(Ion iones[], int x, int y, int l, int r, float dist) {

    int m;

    while(l < r) {
        m = (l + r) / 2;
        if(distanciaEuclidiana(iones[m], x, y) < dist)
            r = m - 1;
        else if(distanciaEuclidiana(iones[m], x, y) > dist)
            l = m + 1;
        else if(distanciaEuclidiana(iones[m], x, y) == dist)
            break;
    }
    return m;
}
*/

/*
bool ionCompare(Ion const & a, Ion const & b)
{
    return a.x < b.x || (a.y <= b.y && a.x == b.x);
}
*/
/*
__global__ void posicionar_ion(float* cargas) {
    int tId = threadIdx.x + blockIdx.x * blockDim.x;

    if(tId < 8192*8192) {
        int a = tId/8192;
        int b = tId%8192;

        minimo_cuda = (cargas[tId] < minimo_cuda) * cargas[tId] + (cargas[tId] >= minimo_cuda) * minimo_cuda;
        minimo_x_cuda = (cargas[tId] < minimo_cuda) * a + (cargas[tId] >= minimo_cuda) * minimo_x_cuda;
        minimo_y_cuda = (cargas[tId] < minimo_cuda) * b + (cargas[tId] >= minimo_cuda) * minimo_y_cuda;
    
        if(cargas[tId] > 0.0)
            printf("MIRA MAMA, SIN MANOS: %f %f %d %d\n", cargas[tId], minimo_cuda, minimo_x_cuda, minimo_y_cuda );
    }
}
*/