`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2015 03:26:51 PM
// Design Name: 
// Module Name: XADCdemo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Versión modificada para calcular la ACF de la señal del XADC antes de enviarla por UART.
//
// Dependencies: ACF_7lag.v, transmitter.vhd, bin2dec.v, DigitToSeg.v
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Fixed timing slack (ArtVVB 06/01/17)
// Revision 1.00 - (Gemini 03/07/24) Integrado módulo ACF_7lag y modificada FSM de UART.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module XADCdemo(
    input CLK100MHZ,
    input reset,        // Reset para la lógica
    output TxD,         // Salida serial
    input vauxp6,
    input vauxn6,
    input vauxp7,
    input vauxn7,
    input vauxp15,
    input vauxn15,
    input vauxp14,
    input vauxn14,
    input vp_in,
    input vn_in,
    input [1:0] sw,
    output reg [15:0] led,
    output [3:0] an,
    output dp,
    output [6:0] seg
    
);

    wire enable;  
    wire ready;         // Señal 'ready' del XADC
    wire [15:0] data;   // Dato crudo del XADC
    reg [6:0] Address_in;
    
    //seven segment controller signals
    reg [32:0] count;
    localparam S_IDLE = 0;
    localparam S_FRAME_WAIT = 1;
    localparam S_CONVERSION = 2;
    reg [1:0] state = S_IDLE;
    reg [15:0] sseg_data;
    
    //binary to decimal converter signals
    reg b2d_start;
    reg [15:0] b2d_din;
    wire [15:0] b2d_dout;
    wire b2d_done;

    //-------------------------------------------------------------------------
    // SEÑALES PARA EL NUEVO BLOQUE ACF Y LA LÓGICA UART MODIFICADA
    //-------------------------------------------------------------------------
    wire acf_done; // Indica que el cálculo de ACF ha terminado
    wire [31:0] acf_lag0, acf_lag1, acf_lag2, acf_lag3, acf_lag4, acf_lag5, acf_lag6, acf_lag7;

    //Señales para controlar el transmisor UART
    reg [3:0] tx_state;       // Estado para la máquina de envío (ampliado)
    reg tx_start;             // Pulso para iniciar la transmisión
    reg [7:0] tx_data_byte;   // Byte de datos a enviar
    wire tx_busy;             // Señal 'busy' desde el transmisor
    
    // Parámetros para la máquina de estados de transmisión (NUEVA)
    localparam TX_IDLE        = 4'b0000;
    localparam TX_LOAD_ACF    = 4'b0001;
    localparam TX_SEND_BYTE   = 4'b0010;
    localparam TX_WAIT_BUSY   = 4'b0011;

    // Contadores para la transmisión
    reg [2:0] lag_counter; // Contador para el lag (0 a 7)
    reg [1:0] byte_counter; // Contador para el byte (0 a 3 de un dato de 32 bits)
    reg [31:0] acf_data_to_send; // Registro para almacenar el dato ACF actual
    //-------------------------------------------------------------------------
    
    //xadc instantiation connect the eoc_out .den_in to get continuous conversion
    xadc_wiz_0  XLXI_7 (
        .daddr_in(Address_in), //addresses can be found in the artix 7 XADC user guide DRP register space
        .dclk_in(CLK100MHZ), 
        .den_in(enable), 
        .di_in(0), 
        .dwe_in(0), 
        .busy_out(),             
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .vauxp7(vauxp7),
        .vauxn7(vauxn7),
        .vauxp14(vauxp14),
        .vauxn14(vauxn14),
        .vauxp15(vauxp15),
        .vauxn15(vauxn15),
        .vn_in(vn_in), 
        .vp_in(vp_in), 
        .alarm_out(), 
        .do_out(data), 
        //.reset_in(),
        .eoc_out(enable),
        .channel_out(),
        .drdy_out(ready)
    );

    //-------------------------------------------------------------------------
    // INSTANCIA DEL NUEVO COMPONENTE ACF_7lag
    //-------------------------------------------------------------------------
    ACF_7lag acf_inst (
        .clk(CLK100MHZ),
        .reset(reset),
        .data_valid(ready), // La señal 'ready' del XADC indica que hay un nuevo dato
        .data_in(data),     // Se conecta el dato crudo del XADC
        .acf_done(acf_done), // Sale una señal cuando el cálculo está listo
        .acf_out_lag0(acf_lag0),
        .acf_out_lag1(acf_lag1),
        .acf_out_lag2(acf_lag2),
        .acf_out_lag3(acf_lag3),
        .acf_out_lag4(acf_lag4),
        .acf_out_lag5(acf_lag5),
        .acf_out_lag6(acf_lag6),
        .acf_out_lag7(acf_lag7)
    );

    // Instancia del transmisor UART (componente VHDL)
    transmitter uart_tx_inst (
        .clk(CLK100MHZ),
        .reset(reset),
        .transmit(tx_start),
        .data(tx_data_byte),
        .TxD(TxD),
        .bussy(tx_busy)
    );

    //-------------------------------------------------------------------------
    // LÓGICA DE CONTROL MODIFICADA PARA LA TRANSMISIÓN UART
    //-------------------------------------------------------------------------
    always @(posedge CLK100MHZ) begin
        if (reset) begin
            tx_state <= TX_IDLE;
            tx_start <= 1'b0;
            lag_counter <= 3'b0;
            byte_counter <= 2'b0;
            acf_data_to_send <= 32'b0;
        end else begin
            tx_start <= 1'b0; // El pulso dura un solo ciclo por defecto
            
            case (tx_state)
                TX_IDLE: begin
                    // Esperar a que el módulo ACF indique que un nuevo cálculo está listo
                    if (acf_done) begin
                        lag_counter <= 3'b0;
                        byte_counter <= 2'b0;
                        tx_state <= TX_LOAD_ACF;
                    end
                end
                
                TX_LOAD_ACF: begin
                    // Cargar el dato de 32 bits del lag correspondiente en un registro
                    case(lag_counter)
                        3'd0: acf_data_to_send <= acf_lag0;
                        3'd1: acf_data_to_send <= acf_lag1;
                        3'd2: acf_data_to_send <= acf_lag2;
                        3'd3: acf_data_to_send <= acf_lag3;
                        3'd4: acf_data_to_send <= acf_lag4;
                        3'd5: acf_data_to_send <= acf_lag5;
                        3'd6: acf_data_to_send <= acf_lag6;
                        3'd7: acf_data_to_send <= acf_lag7;
                    endcase
                    tx_state <= TX_SEND_BYTE;
                end
                
                TX_SEND_BYTE: begin
                    // Seleccionar el byte a enviar y activar la transmisión
                    case(byte_counter)
                        2'd0: tx_data_byte <= acf_data_to_send[7:0];   // Byte menos significativo
                        2'd1: tx_data_byte <= acf_data_to_send[15:8];
                        2'd2: tx_data_byte <= acf_data_to_send[23:16];
                        2'd3: tx_data_byte <= acf_data_to_send[31:24]; // Byte más significativo
                    endcase
                    tx_start <= 1'b1;
                    tx_state <= TX_WAIT_BUSY;
                end

                TX_WAIT_BUSY: begin
                    // Esperar a que el transmisor UART termine de enviar el byte
                    if (!tx_busy) begin
                        if (byte_counter == 2'b11) begin // Si ya se enviaron los 4 bytes
                            byte_counter <= 2'b0;
                            if (lag_counter == 3'b111) begin // Si ya se enviaron los 8 lags
                                tx_state <= TX_IDLE; // Volver a esperar
                            end else begin
                                lag_counter <= lag_counter + 1;
                                tx_state <= TX_LOAD_ACF; // Cargar el siguiente dato de ACF
                            end
                        end else begin
                            byte_counter <= byte_counter + 1;
                            tx_state <= TX_SEND_BYTE; // Enviar el siguiente byte
                        end
                    end
                end
                
                default: tx_state <= TX_IDLE;
            endcase
        end
    end
    
    //led visual dmm (sin cambios)
    always @(posedge(CLK100MHZ)) begin        
        if(ready == 1'b1) begin
            case (data[15:12])
            1:  led <= 16'b11;
            2:  led <= 16'b111;
            3:  led <= 16'b1111;
            4:  led <= 16'b11111;
            5:  led <= 16'b111111;
            6:  led <= 16'b1111111; 
            7:  led <= 16'b11111111;
            8:  led <= 16'b111111111;
            9:  led <= 16'b1111111111;
            10: led <= 16'b11111111111;
            11: led <= 16'b111111111111;
            12: led <= 16'b1111111111111;
            13: led <= 16'b11111111111111;
            14: led <= 16'b111111111111111;
            15: led <= 16'b1111111111111111;                      
            default: led <= 16'b1; 
            endcase
        end
    end
    
    //binary to decimal conversion (sin cambios)
    always @ (posedge(CLK100MHZ)) begin
        case (state)
        S_IDLE: begin
            state <= S_FRAME_WAIT;
            count <= 'b0;
        end
        S_FRAME_WAIT: begin
            if (count >= 10000000) begin
                if (data > 16'hFFD0) begin
                    sseg_data <= 16'h1000;
                    state <= S_IDLE;
                end else begin
                    b2d_start <= 1'b1;
                    b2d_din <= data;
                    state <= S_CONVERSION;
                end
            end else
                count <= count + 1'b1;
        end
        S_CONVERSION: begin
            b2d_start <= 1'b0;
            if (b2d_done == 1'b1) begin
                sseg_data <= b2d_dout;
                state <= S_IDLE;
            end
        end
        endcase
    end
    
    bin2dec m_b2d (
        .clk(CLK100MHZ),
        .start(b2d_start),
        .din(b2d_din),
        .done(b2d_done),
        .dout(b2d_dout)
    );
     
    // Selección de canal (sin cambios)
    always @(posedge(CLK100MHZ)) begin
        case(sw)
        0: Address_in <= 8'h16; // XA1/AD6
        1: Address_in <= 8'h1e; // XA2/AD14
        2: Address_in <= 8'h17; // XA3/AD7
        3: Address_in <= 8'h1f; // XA4/AD15
        endcase
    end
    
    DigitToSeg segment1(
        .in1(sseg_data[3:0]),
        .in2(sseg_data[7:4]),
        .in3(sseg_data[11:8]),
        .in4(sseg_data[15:12]),
        .in5(),
        .in6(),
        .in7(),
        .in8(),
        .mclk(CLK100MHZ),
        .an(an),
        .dp(dp),
        .seg(seg)
    );
endmodule