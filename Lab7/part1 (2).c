#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

volatile int pixel_buffer_start; // global variable
void plot_pixel(int x, int y, short int line_color);
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, short int colour);
void swap(int* first_number, int* second_number);

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

    clear_screen();
    draw_line(0, 0, 150, 150, 0x001F);   // this line is blue
    draw_line(150, 150, 319, 0, 0x07E0); // this line is green
    draw_line(0, 239, 319, 239, 0xF800); // this line is red
    draw_line(319, 0, 0, 239, 0xF81F);   // this line is a pink color
	
	return 0;
}

// code not shown for clear_screen() and draw_line() subroutines

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void clear_screen()
{
	int x = 0;
	int y = 0;
	for(y = 0; y < 240; y++){
		for (x = 0; x < 320; x++){
			plot_pixel(x,y, 0x0);
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

void swap(int* first_number, int* second_number){
	int temp = 0;
	
	temp = *first_number;
	*first_number = *second_number;
	*second_number = temp;
}