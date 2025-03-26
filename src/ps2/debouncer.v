module debouncer(
    input i_clk,            // System clock
    input i_in,      // Input signal (button or switch)
    output reg o_out // Output signal (debounced)
);
    // Parameters
    parameter N = 3;     // Size of counter for debouncing (higher N = more stable, but slower response)
    
    // Internal signals
    reg [N-1:0] count = 0;   // Counter to sample the input signal
    reg i_in_reg = 0;    // Reg to hold the previous value of the input signal
    reg i_in_stable = 0; // Signal to hold the stable state of the input signal

    // Debounce logic
    always @(posedge i_clk) begin
          // Shift the button input signal and sample it periodically
          if (i_in == i_in_reg) begin
              // If the input signal is stable, increment the counter
              if (count < {N{1'b1}}) begin
                  count <= count + 1;
              end else begin
                  // If the counter reaches the maximum value, update the stable state
                  i_in_stable <= i_in_reg;
              end
          end else begin
              // Reset the counter if the input signal changes
              count <= 0;
          end

          // Update the previous input value
          i_in_reg <= i_in;

          // Output the stable value
          o_out <= i_in_stable;
    end
endmodule
