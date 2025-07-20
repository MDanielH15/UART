`timescale 1ns / 1ps

module ACF_7lag(
    input clk,
    input reset,
    input data_valid,      // Señal que indica que 'data_in' es válido (ej. 'ready' del XADC)
    input [15:0] data_in,  // Dato de entrada de 16 bits desde el XADC

    output reg acf_done,         // Pulso que indica que el cálculo ha terminado
    output reg [31:0] acf_out_lag0, // Resultado de la autocorrelación para lag = 0
    output reg [31:0] acf_out_lag1, // Resultado de la autocorrelación para lag = 1
    output reg [31:0] acf_out_lag2, // Resultado de la autocorrelación para lag = 2
    output reg [31:0] acf_out_lag3, // Resultado de la autocorrelación para lag = 3
    output reg [31:0] acf_out_lag4, // Resultado de la autocorrelación para lag = 4
    output reg [31:0] acf_out_lag5, // Resultado de la autocorrelación para lag = 5
    output reg [31:0] acf_out_lag6, // Resultado de la autocorrelación para lag = 6
    output reg [31:0] acf_out_lag7  // Resultado de la autocorrelación para lag = 7
    );

    // Registros de desplazamiento para almacenar las muestras anteriores x[n-1] a x[n-7]
    // Se necesitan 7 registros para 7 lags.
    reg signed [15:0] data_reg_1; // Almacena x[n-1]
    reg signed [15:0] data_reg_2; // Almacena x[n-2]
    reg signed [15:0] data_reg_3; // Almacena x[n-3]
    reg signed [15:0] data_reg_4; // Almacena x[n-4]
    reg signed [15:0] data_reg_5; // Almacena x[n-5]
    reg signed [15:0] data_reg_6; // Almacena x[n-6]
    reg signed [15:0] data_reg_7; // Almacena x[n-7]

    // Se usa 'signed' para las multiplicaciones para manejar correctamente los números
    reg signed [15:0] signed_data_in;

    // Lógica de procesamiento
    always @(posedge clk) begin
        if (reset) begin
            // Reseteo de todos los registros
            data_reg_1 <= 16'd0;
            data_reg_2 <= 16'd0;
            data_reg_3 <= 16'd0;
            data_reg_4 <= 16'd0;
            data_reg_5 <= 16'd0;
            data_reg_6 <= 16'd0;
            data_reg_7 <= 16'd0;
            
            acf_out_lag0 <= 32'd0;
            acf_out_lag1 <= 32'd0;
            acf_out_lag2 <= 32'd0;
            acf_out_lag3 <= 32'd0;
            acf_out_lag4 <= 32'd0;
            acf_out_lag5 <= 32'd0;
            acf_out_lag6 <= 32'd0;
            acf_out_lag7 <= 32'd0;
            
            acf_done <= 1'b0;
            signed_data_in <= 16'd0;
        end else begin
            // El pulso 'acf_done' dura solo un ciclo de reloj
            acf_done <= 1'b0;
            
            // Cuando llega un nuevo dato válido del XADC
            if (data_valid) begin
                // Convertir la entrada a 'signed' para la multiplicación
                signed_data_in <= data_in;
            
                // 1. Desplazar los registros para actualizar las muestras anteriores
                data_reg_1 <= signed_data_in; // La muestra actual se convierte en x[n-1] en el siguiente ciclo
                data_reg_2 <= data_reg_1;   // x[n-1] se convierte en x[n-2]
                data_reg_3 <= data_reg_2;
                data_reg_4 <= data_reg_3;
                data_reg_5 <= data_reg_4;
                data_reg_6 <= data_reg_5;
                data_reg_7 <= data_reg_6;
                
                // 2. Calcular todas las autocorrelaciones en paralelo
                // La multiplicación de dos números de 16 bits resulta en 32 bits.
                acf_out_lag0 <= signed_data_in * signed_data_in; // x[n] * x[n]
                acf_out_lag1 <= signed_data_in * data_reg_1;     // x[n] * x[n-1]
                acf_out_lag2 <= signed_data_in * data_reg_2;     // x[n] * x[n-2]
                acf_out_lag3 <= signed_data_in * data_reg_3;     // x[n] * x[n-3]
                acf_out_lag4 <= signed_data_in * data_reg_4;     // x[n] * x[n-4]
                acf_out_lag5 <= signed_data_in * data_reg_5;     // x[n] * x[n-5]
                acf_out_lag6 <= signed_data_in * data_reg_6;     // x[n] * x[n-6]
                acf_out_lag7 <= signed_data_in * data_reg_7;     // x[n] * x[n-7]
                
                // 3. Indicar que el cálculo ha finalizado y los datos de salida son válidos
                acf_done <= 1'b1;
            end
        end
    end

endmodule

