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

void valor_q(float iones_x[], float iones_y[], int cantidad){
    int a,b;
    float Q_menor=100000000.0;
    float carga=0;
    int distancia;
    int menor[2];
    float x_2,y_2;
    for(a=0; a<8192; a++){
        for(b=0; b<8192; b++){
            carga=0;
            for(int i = 0; i < cantidad; i++){
                x_2=(a-iones_x[i])*(a-iones_x[i]);
                y_2=(b-iones_y[i])*(b-iones_y[i]);
                distancia = sqrt(x_2+y_2);
                if (distancia==0){
                    distancia=0.0000000000001;
                }
                carga+=1.0/distancia;
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
    float *iones_x, *iones_y;
    float x, y;

    iones_x = new float[6000];
	iones_y = new float[6000];

    std::random_device rd;
    std::default_random_engine generator(rd()); // rd() provides a random seed
    std::uniform_real_distribution<double> distribution(0.1,8192);

    for (int i = 0; i < 5000; ++i){

        x = distribution(generator);
        y = distribution(generator);
        iones_x[i]=x;
        iones_y[i]=y;
	}
    int cantidad;
    for(cantidad=5000; cantidad < 6000; cantidad++){
        valor_q(iones_x, iones_y, cantidad);
    }


    return 0;
}