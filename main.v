`timescale 1ns / 1ps

module bin2bcd(
    input [5:0] bin_in,
    output reg [2:0] tens,      // max value 101
    output reg [3:0] ones       // max value 1001
    );
    
    always @* begin
        tens <= bin_in / 10;
        ones <= bin_in % 10;
    end
    
endmodule

module btn_debouncer(
    input clk_100MHz,
    input btn_in,
    output btn_out
    );
    
    reg temp1, temp2, temp3;
    
    always @(posedge clk_100MHz) begin
        temp1 <= btn_in;
        temp2 <= temp1;
        temp3 <= temp2;
    end
    
    assign btn_out = temp3;
    
endmodule

module hours(
    input inc_hours,        // From minutes
    input reset,
    output [3:0] hours
    );
    
    reg [3:0] hrs_ctr = 12;
    
    always @(negedge inc_hours or posedge reset) begin
        if(reset)
            hrs_ctr <= 12;
        else
            if(hrs_ctr == 12)
                hrs_ctr <= 1;
            else
                hrs_ctr <= hrs_ctr + 1;
    end
    
    assign hours = hrs_ctr;
    
endmodule

module minutes(
    input inc_minutes,      // From seconds
    input reset,
    output inc_hours,       // To hours
    output [5:0] minutes    // For LEDs
    );
    
    reg [5:0] min_ctr = 0;
    
    always @(negedge inc_minutes or posedge reset) begin
        if(reset)
            min_ctr <= 0;
        else
            if(min_ctr == 59)
                min_ctr <= 0;
            else
                min_ctr <= min_ctr + 1;
    end
    
    assign inc_hours = (min_ctr == 59) ? 1 : 0;
    assign minutes = min_ctr;
    
endmodule

module oneHz_generator(
    input clk_100MHz,       // 100MHz BASYS 3
    output clk_1Hz
    );
    
    reg [25:0] counter_reg = 0;
    reg clk_out_reg = 0;
    
    always @(posedge clk_100MHz) begin
        if(counter_reg == 49_999_999) begin
            counter_reg <= 0;
            clk_out_reg <= ~clk_out_reg;
        end
        else
            counter_reg <= counter_reg + 1;
    end
    
    assign clk_1Hz = clk_out_reg;
    
endmodule


module seconds(
    input clk_1Hz,      // From oneHz_generator
    input reset,
    output inc_minutes  // To minutes
    );
    
    reg [5:0] sec_ctr = 0;
    
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            sec_ctr <= 0;
        else
            if(sec_ctr == 59) 
                sec_ctr <= 0;
            else
                sec_ctr <= sec_ctr + 1;
    end
    
    assign inc_minutes = (sec_ctr == 59) ? 1 : 0;
    
endmodule

module seg7_control(
    input clk_100MHz,
    input reset,
    input [2:0] hrs_tens,
    input [3:0] hrs_ones,
    input [2:0] mins_tens,
    input [3:0] mins_ones,
    output reg [0:6] seg,
    output reg [3:0] an
    );
    
    // Parameters for segment values
    parameter NULL  = 7'b111_1111;  // Turn off all segments
    parameter ZERO  = 7'b000_0001;  // 0
    parameter ONE   = 7'b100_1111;  // 1
    parameter TWO   = 7'b001_0010;  // 2 
    parameter THREE = 7'b000_0110;  // 3
    parameter FOUR  = 7'b100_1100;  // 4
    parameter FIVE  = 7'b010_0100;  // 5
    parameter SIX   = 7'b010_0000;  // 6
    parameter SEVEN = 7'b000_1111;  // 7
    parameter EIGHT = 7'b000_0000;  // 8
    parameter NINE  = 7'b000_0100;  // 9
    
    
    // To select each anode in turn
        reg [1:0] anode_select;
        reg [16:0] anode_timer;
        
        always @(posedge clk_100MHz or posedge reset) begin
            if(reset) begin
                anode_select <= 0;
                anode_timer <= 0; 
            end
            else
                if(anode_timer == 99_999) begin
                    anode_timer <= 0;
                    anode_select <=  anode_select + 1;
                end
                else
                    anode_timer <=  anode_timer + 1;
        end
        
        always @(anode_select) begin
            case(anode_select) 
                2'b00 : an = 4'b0111;
                2'b01 : an = 4'b1011;
                2'b10 : an = 4'b1101;
                2'b11 : an = 4'b1110;
            endcase
        end
    
    // To drive the segments
    always @*
        case(anode_select)
            2'b00 : begin       // HOURS TENS DIGIT
                        case(hrs_tens)
                            3'b000 : seg = NULL;
                            3'b001 : seg = ONE;
                        endcase
                    end
                    
            2'b01 : begin       // HOURS ONES DIGIT
                        case(hrs_ones)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
                    
            2'b10 : begin       // MINUTES TENS DIGIT
                        case(mins_tens)
                            3'b000 : seg = ZERO;
                            3'b001 : seg = ONE;
                            3'b010 : seg = TWO;
                            3'b011 : seg = THREE;
                            3'b100 : seg = FOUR;
                            3'b101 : seg = FIVE;
                        endcase
                    end
                    
            2'b11 : begin       // MINUTES ONES DIGIT
                        case(mins_ones)
                            4'b0000 : seg = ZERO;
                            4'b0001 : seg = ONE;
                            4'b0010 : seg = TWO;
                            4'b0011 : seg = THREE;
                            4'b0100 : seg = FOUR;
                            4'b0101 : seg = FIVE;
                            4'b0110 : seg = SIX;
                            4'b0111 : seg = SEVEN;
                            4'b1000 : seg = EIGHT;
                            4'b1001 : seg = NINE;
                        endcase
                    end
        endcase
  
endmodule

module top_bin_clock(
    input clk_100MHz,       // from Basys 3
    input reset,            // btnC Basys 3
    input inc_mins,         // btnR Basys 3
    input inc_hrs,          // btnL Basys 3
    output [3:0] hours,     // Internal
    output sig_1Hz,         // Internal
    output [5:0] minutes    // Internal
    );
    
    wire w_1Hz;                                 // 1Hz signal
    wire inc_hrs_db, reset_db, inc_mins_db;     // debounced button signals
    wire w_inc_mins, w_inc_hrs;                 // mod to mod
    wire inc_mins_or, inc_hrs_or;               // from OR gates
    
    btn_debouncer bL(.clk_100MHz(clk_100MHz), .btn_in(inc_hrs), .btn_out(inc_hrs_db));
    btn_debouncer bC(.clk_100MHz(clk_100MHz), .btn_in(reset), .btn_out(reset_db));
    btn_debouncer bR(.clk_100MHz(clk_100MHz), .btn_in(inc_mins), .btn_out(inc_mins_db));
    oneHz_generator uno(.clk_100MHz(clk_100MHz), .clk_1Hz(w_1Hz));
    seconds sec(.clk_1Hz(w_1Hz), .reset(reset_db), .inc_minutes(w_inc_mins));
    minutes min(.inc_minutes(inc_mins_or), .reset(reset_db), .inc_hours(w_inc_hrs), .minutes(minutes));
    hours hr(.inc_hours(inc_hrs_or), .reset(reset_db), .hours(hours));
    
    assign inc_hrs_or = w_inc_hrs | inc_hrs_db;
    assign inc_mins_or = w_inc_mins | inc_mins_db;
    assign sig_1Hz = w_1Hz;
    
endmodule

module top_7seg_clock(
    input clk_100MHz,
    input reset,
    input inc_hrs,
    input inc_mins,
    output blink,
    output [0:6] seg,
    output [3:0] an
    );
    
    wire [3:0] v_hours;
    wire [5:0] v_minutes, hours_pad;
    wire [2:0] hrs_tens, mins_tens;
    wire [3:0] hrs_ones, mins_ones;
    
    // Binary Clock
    top_bin_clock bin(.clk_100MHz(clk_100MHz), .reset(reset), .inc_hrs(inc_hrs), .inc_mins(inc_mins),
                      .sig_1Hz(blink), .hours(v_hours), .minutes(v_minutes));
    
    // New modules for segment display
    bin2bcd hrs(.bin_in(hours_pad), .tens(hrs_tens), .ones(hrs_ones));
    bin2bcd mins(.bin_in(v_minutes), .tens(mins_tens), .ones(mins_ones));
    seg7_control seg7(.clk_100MHz(clk_100MHz), .reset(reset), .hrs_tens(hrs_tens), .hrs_ones(hrs_ones), .mins_tens(mins_tens), 
                      .mins_ones(mins_ones), .seg(seg), .an(an));
    
    assign hours_pad = {2'b00, v_hours};     // Pad hours vector with zeros to size for bin2bcd
    
endmodule