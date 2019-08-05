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

void valor_q(int iones_x[], int iones_y[], int cantidad)
{
    int a, b;
    float Q_menor = 100000000.0;
    float carga = 0;
    float distancia;
    int menor[2];
    float x_2, y_2;
    cout << "Posicionando ion " << cantidad << endl;
    for (a = 0; a < 8192; a++)
    {
        cout << "calculando " << a << " " << b << endl;
        for (b = 0; b < 8192; b++)
        {
            carga = 0;

            for (int i = 0; i < cantidad; i++)
            {
                x_2 = (a - iones_x[i]) * (a - iones_x[i]);
                y_2 = (b - iones_y[i]) * (b - iones_y[i]);
                distancia = sqrt(x_2 + y_2);
                if (distancia == 0)
                {
                    distancia = 0.0000000000001;
                }
                carga += 1.0 / distancia;
            }
            if (carga < Q_menor)
            {
                Q_menor = carga;
                menor[0] = a;
                menor[1] = b;
            }
        }
    }
    iones_x[cantidad] = menor[0];
    iones_y[cantidad] = menor[1];
}

int main(int argc, char const *argv[])
{
    int *iones_x, *iones_y;
    iones_x = new int[6000];
    iones_y = new int[6000];

    FILE *in = fopen("dataset", "r");
    for (int i = 0; i < 5000; i++)
    {
        fscanf(in, "%i %i", &iones_x[i], &iones_y[i]);
        cout << iones_x[i] << " " << iones_y[i] << endl;
    }

    int cantidad;
    clock_t t1, t2;
    double ms;

    t1 = clock();
    for (cantidad = 5000; cantidad < 5001; cantidad++)
    {
        valor_q(iones_x, iones_y, cantidad);
    }

    t2 = clock();
    ms = 1000.0 * (double)(t2 - t1) / CLOCKS_PER_SEC;
    cout << "Tiempo CPU: " << ms << " [ms]" << endl;

    delete iones_x;
    delete iones_y;
    return 0;
}