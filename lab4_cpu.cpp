#include <iostream>
#include <fstream>
#include <string>
#include <stdio.h>
#include <stdlib.h>
using namespace std;
#include <iterator>
#include <algorithm>
#include <math.h>

void valor_q(float iones_x[], float iones_y[], int cantidad){
    int a,b;
    int Q_menor=100000000;
    int carga=0;
    int distancia;
    int menor[2];

    for(a=0; a<8192; a++){
        for(b=0; b<8192; b++){
            carga=0;
            for(int i = 0; i < cantidad; i++){
                distancia = sqrt((a-iones_x[i])*(a-iones_x[i])+(b-iones_y[i])*(b-iones_y[i]));
                if (distancia==0){
                    distancia=0.00000000000000000000000000000001;
                }
                carga+=1/distancia;
            }
            if(carga < Q_menor){
                Q_menor=carga;
                menor[0]=a;
                menor[1]=b;
            }
        }
    }
    iones_x[cantidad]=menor[0];
    iones_y[cantidad]=menor[1];
}

int main(int argc, char const *argv[]){
    srand48(time(NULL));
    float *iones_x[6000], *iones_y[6000];
    float x, y;
    
    for (int i = 0; i < 5000; ++i){

        x = drand48()*8192;
        y = drand48()*8192;

        *iones_x[i]=x;
        *iones_y[i]=y;

	}
    int cantidad;
    for(cantidad=5000; cantidad < 1000; cantidad++){
        valor_q(*iones_x, *iones_y, cantidad);
    }


    return 0;
}