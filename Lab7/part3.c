#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

volatile int pixel_buffer_start; // global variable
//volatile int first_buffer = 0xC0000000
int box_x[8],box_y[8],box_dx[8],box_dy[8],color[8];
int box_x_prev_SDRAM[8],box_y_prev_SDRAM[8];
int box_x_prev_ONCHIP[8],box_y_prev_ONCHIP[8];
void clear_screen();
void draw_line(int x_start, int y_start, int x_end, int y_end, short int line_color);
void plot_pixel(int x, int y, short int line_color);
void swap(int* first_number, int* second_number);
void wait_for_sync();
void draw();
void update();
void clear();


int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // declare other variables(not shown)
    // initialize location and direction of rectangles(not shown)

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_sync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
	
	int i;
	for(i = 0; i < 8; i++){
	    box_dx[i] = rand()%2 - 1; // 1 or -1
		if(box_dx[i] == 0){
			box_dx[i] = -1;
			box_dy[i] = rand()%2 - 1; // 1 or -1
		}if(box_dy[i] == 0){
			box_dy[i] = -1;
			color[i] = rand()%8;	
			box_x[i] = rand()%319;
			box_y[i] = rand()%239;
			box_x_prev_ONCHIP[i] = box_x[i];
			box_y_prev_ONCHIP[i] = box_y[i];
			box_x_prev_SDRAM[i] = box_x[i];
			box_y_prev_SDRAM[i] = box_y[i];
		}
	}
	
    while (1){
       // clear_screen_partial();
	    clear();
        // code for drawing the boxes and lines (not shown)
		draw();
        // code for updating the locations of boxes (not shown)
		update();
        wait_for_sync(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
    }
}

void clear(){	
	int i;
	if(pixel_buffer_start == 0xC0000000){
		for(i = 0; i < 8; i++){
				plot_pixel(box_x_prev_SDRAM[i],box_y_prev_SDRAM[i],0x000);
				plot_pixel(box_x_prev_SDRAM[i]+1,box_y_prev_SDRAM[i],0x000);
				plot_pixel(box_x_prev_SDRAM[i],box_y_prev_SDRAM[i]+1,0x0000);
				plot_pixel(box_x_prev_SDRAM[i]+1,box_y_prev_SDRAM[i]+1,0x00);			
				if(i == 7){
					draw_line(box_x_prev_SDRAM[i],box_y_prev_SDRAM[i],box_x_prev_SDRAM[0],box_y_prev_SDRAM[0],0x0000);
				}
				else{
					draw_line(box_x_prev_SDRAM[i],box_y_prev_SDRAM[i],box_x_prev_SDRAM[i+1],box_y_prev_SDRAM[i+1],0x0000);
				}
			}
	}	
	else if(pixel_buffer_start == 0xC8000000){
		for(i = 0; i < 8; i++){
				plot_pixel(box_x_prev_ONCHIP[i],box_y_prev_ONCHIP[i],0x000);
				plot_pixel(box_x_prev_ONCHIP[i]+1,box_y_prev_ONCHIP[i],0x000);
				plot_pixel(box_x_prev_ONCHIP[i],box_y_prev_ONCHIP[i]+1,0x0000);
				plot_pixel(box_x_prev_ONCHIP[i]+1,box_y_prev_ONCHIP[i]+1,0x00);			
				if(i == 7){
					draw_line(box_x_prev_ONCHIP[i],box_y_prev_ONCHIP[i],box_x_prev_ONCHIP[0],box_y_prev_ONCHIP[0],0x0000);
				}
				else{
					draw_line(box_x_prev_ONCHIP[i],box_y_prev_ONCHIP[i],box_x_prev_ONCHIP[i+1],box_y_prev_ONCHIP[i+1],0x0000);
				}
			}		
	}	
}

// code for subroutines (not shown)
void draw(){
	int i;
	
	for(i = 0; i < 8; i++){
		plot_pixel(box_x[i],box_y[i],0x07E0);
		plot_pixel(box_x[i]+1,box_y[i],0x07E0);
		plot_pixel(box_x[i],box_y[i]+1, 0x07E0);
		plot_pixel(box_x[i]+1,box_y[i]+1,0x07E0);			
		if(i == 7){
			draw_line(box_x[i],box_y[i],box_x[0],box_y[0],0x001F);
		}
		else{
			draw_line(box_x[i],box_y[i],box_x[i+1],box_y[i+1],0x001F);
		}
	}			
}

// code not shown for clear_screen() and draw_line() subroutines
void update(){
	int i;
	
	for(i = 0; i < 8; i++){
	    if(pixel_buffer_start == 0xC0000000){
			box_x_prev_SDRAM[i] = box_x[i];
			box_y_prev_SDRAM[i] = box_y[i];
		}
		else if(pixel_buffer_start == 0xC8000000){
			box_x_prev_ONCHIP[i] = box_x[i];
			box_y_prev_ONCHIP[i] = box_y[i];
		}
		
		if((box_x[i] + 1) == 319){
			box_dx[i] = -1 * box_dx[i];
		}
		else if(box_x[i] == 0){
			box_dx[i] = -1 * box_dx[i];
		}
		
		if((box_y[i] + 1) == 239){
			box_dy[i] = -1 * box_dy[i];
		}
		else if(box_y[i] == 0){
			box_dy[i] = -1 * box_dy[i];
		}		
		box_x[i] = box_x[i] + box_dx[i];
		box_y[i] = box_y[i] + box_dy[i];					
	}
}
// code not shown for clear_screen() and draw_line() subroutines
void clear_screen(){
		int i;
		
		for(i = 0xC8000000; i < 0xC803BE7E; i = i + 2){
			*(short int *)(i) = 0x0000;
		}
		
		
		for(i = 0xC0000000; i < 0xC003BE7E; i = i + 2){
			*(short int *)(i) = 0x0000;
		}
}


void draw_line(int x0, int y0, int x1, int y1, short int colour){
	
	bool is_steep = abs(y1 - y0) > abs(x1 - x0);
	
	if (is_steep){
		swap(&x0, &y0);
		swap(&x1, &y1);
	}

	if (x0 > x1){
		swap(&x0, &x1);
		swap(&y0, &y1);
	}
	
	int delta_x = x1 - x0;
	int delta_y = abs(y1 - y0);
	int error = -(delta_x / 2);
	int y = y0;
	int y_step;
	
	if (y0 < y1)
		y_step = 1;
	else 
		y_step = -1;
	
	int x_index;
	
	for(x_index = x0; x_index < x1 + 1; x_index++){
		if (is_steep)
 			plot_pixel(y, x_index, colour);
 		else
			plot_pixel(x_index, y, colour);

		error = error + delta_y;

		if (error >= 0){
			y = y + y_step;
			error = error - delta_x;
		}
	}
}



void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void wait_for_sync(){
	volatile int* pixel_ctrl_ptr = 0xFF203020;
	register int status;
	
	*pixel_ctrl_ptr = 1;
	
	status = *(pixel_ctrl_ptr + 3);
	while((status & 0x01)!=0){
		status = *(pixel_ctrl_ptr + 3);
	}
	return; 
}

void swap(int* first_number, int* second_number){
	int temp = 0;
	
	temp = *first_number;
	*first_number = *second_number;
	*second_number = temp;
}