#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

volatile int pixel_buffer_start; // global variable
void plot_pixel(int x, int y, short int line_color);
void clear_screen();
void draw_line(int x0, int x1, int y0, int y1, short int colour);
void swap(int* first_number, int* second_number);
void wait_for_vsync();

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;
	*(pixel_ctrl_ptr+1) = pixel_buffer_start;
	
    clear_screen();
	
	int x = 50;
    int y = 0;
    int dy = 1;
    
	
	while(1){
		wait_for_vsync();
        //erase line
        draw_line(x, y, x + 260, y, 0x0);
        //move up or down
        y += dy;
        draw_line(x, y, x + 260, y, 0xFFFF);
        if(y >= 239 || y <= 0){
            dy = dy * -1;
		}
	}
	
	return 0;
}

// code not shown for clear_screen() and draw_line() subroutines

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void clear_screen(){
	int x = 0;
	int y = 0;
	for(y = 0; y < 240; ++y){
		for (x = 0; x < 320; ++x){
			*(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = 0;
		}
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

void wait_for_vsync(){
    volatile int *pixel_ctrl_ptr = 0xFF203020; //pixel controller
    register int status;
     
    *pixel_ctrl_ptr = 1; //start sync
     
    status = *(pixel_ctrl_ptr + 3);
    while ((status & 0x01) != 0){
        status = *(pixel_ctrl_ptr + 3);
    }
}

void swap(int* first_number, int* second_number){
	int temp = 0;
	
	temp = *first_number;
	*first_number = *second_number;
	*second_number = temp;
}