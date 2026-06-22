
// Thomas Cowie
// VGA GAME 
// Adapted from Tiny Tapeout VGA playground
`default_nettype none


parameter LOGO_SIZE = 128;      // Size of the logo in pixels
parameter DISPLAY_WIDTH = 640;   // Width of visible screen (pixels)
parameter DISPLAY_HEIGHT = 480;  // Height of visible screen (pixels)


module tt_um_vga_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Set all unused pins to 0
  assign uio_out = 8'd0;
  assign uio_oe  = 8'd0;

 // Defining all inputs
  wire hsync;
  wire vsync;
  reg [1:0] R;
  reg [1:0] G;
  reg [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  wire inp_up;
  wire inp_down;
  wire inp_left;
  wire inp_right;
  wire gamepad_present;

  // TinyVGA PMOD Hardware Mapping
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};


  // The initial starting centre coordinates of the image
  reg [9:0] logo_left = 10'd246; 
  reg [9:0] logo_top  = 10'd176;  


  localparam [9:0] LOGO_TOP_MAX = DISPLAY_HEIGHT - LOGO_SIZE;  // 480-128 = 352
  localparam [9:0] LOGO_LEFT_MAX = DISPLAY_WIDTH - LOGO_SIZE;  // 
  // Ammount of pixels the sprite moves when a button is pressed
  localparam [9:0] STEP         = 10'd10;

  // Defines the boundary of the sprite's frame
  // Focus on top and left of the frame as the electron beam
  // moves from the top left of the screen to the bottom right 
  wire [9:0] left_bound = pix_x - logo_left;
  wire [9:0] top_bound  = pix_y - logo_top;

  // This is high if the electron beam is within the sprite's frame 
  wire logo_window = (left_bound < LOGO_SIZE) && (top_bound < LOGO_SIZE);

  wire pixel_value;


 // Controller variables 
  reg inp_up_prev;
  wire up_pressed = inp_up & ~inp_up_prev;

  reg inp_down_prev;
  wire down_pressed = inp_down & ~inp_down_prev;

  reg inp_left_prev; 
  wire left_pressed = inp_left & ~inp_left_prev;

  reg inp_right_prev; 
  wire right_pressed = inp_right & ~inp_right_prev;



  


  hvsync_generator vga_sync_gen (
      .clk(clk),
      .reset(~rst_n),
      .hsync(hsync),
      .vsync(vsync),
      .display_on(video_active),
      .hpos(pix_x),
      .vpos(pix_y)
  );

  gamepad_pmod_single driver (
      // Inputs:
      .rst_n(rst_n),
      .clk(clk),
      .pmod_data(ui_in[6]),
      .pmod_clk(ui_in[5]),
      .pmod_latch(ui_in[4]),
      // Outputs:
      .up(inp_up),
      .down(inp_down),
      .left(inp_left),
      .right(inp_right),
      .is_present(gamepad_present)
  );
  // Instantiate the Stick Man ROM
  bitmap_rom rom1 (
      .x(left_bound[6:0]),
      .y(top_bound[6:0]),
      .pixel(pixel_value)
  );


  always @(posedge clk) begin
    // Active low reset
    // If reset low then the screen is set to black
    if (~rst_n) begin
      R <= 2'b00;
      G <= 2'b00;
      B <= 2'b00;

      inp_up_prev   <= 1'b0;
      inp_down_prev <= 1'b0;
    end else begin

      // Default background color: Black
      R <= 2'b00;
      G <= 2'b00;
      B <= 2'b00;

      // Draws the sprite on the screen
      if (video_active && logo_window && pixel_value) begin
        R <= 2'b11;
        G <= 2'b11;
        B <= 2'b11;
      end

      // Track last cycle's button state so up_pressed/down_pressed can detect a fresh edge.
      inp_up_prev   <= inp_up;
      inp_down_prev <= inp_down;
      inp_left_prev <= inp_left;
      inp_right_prev <= inp_right;

      // If up arrow is pressed the sprite moves up by 'STEP' pixels
      // Can't move up off the screen.
      if (up_pressed && logo_top >= STEP) begin
        logo_top <= logo_top - STEP;
      end

      // If down arrow is pressed the sprite moves down by 'STEP' pixels
      // Can't move down off the screen
      if (down_pressed && logo_top <= (LOGO_TOP_MAX - STEP)) begin
        logo_top <= logo_top + STEP;
      end

      if (left_pressed && logo_left <= LOGO_LEFT_MAX ) begin
        logo_left <= logo_left - STEP;
      end

      if (right_pressed && logo_left <= (LOGO_LEFT_MAX - STEP)  ) begin
        logo_left <= logo_left + STEP;
      end


    end
  end

endmodule

// End
