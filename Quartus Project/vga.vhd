library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_control is
port(
	mode:	in std_logic;
	clk:	in std_logic;
	reset:	in std_logic;
	vsync:	out std_logic;
	hsync:	out std_logic;
	red:	out std_logic_vector(3 downto 0);
	green:	out std_logic_vector(3 downto 0);
	blue:	out std_logic_vector(3 downto 0);
	counterh: out unsigned(10 downto 0);
	counterv: out unsigned(10 downto 0);
	hfin : out std_logic;
	vfin: out std_logic
	);
end vga_control;

architecture arch of vga_control is
	constant PPL: integer:= 1280;	-- pixels per line
	constant HFP: integer:= 48;		-- hsync front porch
	constant HBP: integer:= 248;	-- hsync back porch
	constant HRE: integer:= 112;	-- hsync retrace
	constant LIN: integer:= 1024;	-- vertical lines
	constant VFP: integer:= 1;		-- vsync front porch
	constant VBP: integer:= 38;		-- vsync vakc porch
	constant VRE: integer:= 3;		-- vsync retrace

	-- counter variables
	signal count_1688, count_1688_next: unsigned(10 downto 0);
	signal count_1066, count_1066_next: unsigned(10 downto 0);

	-- control variables
	signal h_end, v_end: std_logic;

	signal vsync_reg, vsync_reg2: std_logic;
	signal hsync_reg, hsync_reg2: std_logic;

	signal red_reg, blue_reg, green_reg: std_logic_vector(3 downto 0);
	signal output_colour: std_logic_vector(11 downto 0);

	begin

	process (clk, reset)
		begin
		if (reset = '1') then	
			-- Reset signals
			--count_1688 <= (others => '0');
			--count_1066 <= (others => '0');
			--h_end <= '0';
			--v_end <= '0';
			--hsync_reg <= '0';
			--vsync_reg <= '0';

		elsif (rising_edge(clk)) then
			-- Sync output control signals
			vsync_reg2 <= vsync_reg;
			vsync <= vsync_reg2;
			hsync_reg2 <= hsync_reg;
			hsync <= hsync_reg2;

			--Sync colours
--			red_reg <= output_colour(11 downto 8);
--			red <= red_reg;
--			green_reg <= output_colour(7 downto 4);
--			green <= green_reg;
--			blue_reg <= output_colour(3 downto 0);
--			blue <= blue_reg;
			
			red <= output_colour(11 downto 8);
			green <= output_colour(7 downto 4);
			blue <= output_colour(3 downto 0);
		end if;
	end process;

	-- 1688 counter, clock times for horizontal pixels
	counter1688: process (clk, reset)
		begin
		if (reset = '1') then
			count_1688_next <= (others => '0');
		elsif (rising_edge(clk)) then
			if (h_end = '1') then
				count_1688_next <= (others => '0');
			else
				count_1688_next <= count_1688 + 1;
			end if;
		end if;
	end process;


	counter1066: process (clk, reset)
		begin
		if (reset = '1') then
			count_1066_next <= (others => '0');
		elsif (rising_edge(clk)) then
			if (v_end = '1') then
				count_1066_next <= (others => '0');
			elsif (h_end = '1') then
				count_1066_next <= count_1066 + 1;
			end if;
		end if;
	end process;

	signalgen: process (clk, reset)
		begin
		--TODO: implement the colour clock
			if (reset = '1')  then 
				output_colour <= (others => '0');
			elsif (rising_edge(clk)) then
				if (mode = '0') then
					if (HFP > count_1688) then
						output_colour <= (others => '0');
					elsif (HFP+426 > count_1688) then
						output_colour <= "000000001111";
					elsif (HFP+852 > count_1688) then
						output_colour <= "000011110000";
					elsif (HFP+1280 > count_1688) then
						output_colour <= "011100000000";
					else
						output_colour <= (others => '0');
					end if;
				elsif (mode = '1') then
					if (VFP > count_1066) then
						output_colour <= (others => '0');
					elsif (VFP+342 > count_1066) then
						output_colour <= "000000001111";
					elsif (VFP+682 > count_1066) then
						output_colour <= "000011110000";
					elsif (VFP+1024 > count_1066) then
						output_colour <= "011100000000";
					else
						output_colour <= (others => '0');
					end if;
				end if;
			end if;		
	end process;

	hsync_reg <= '1' when count_1688_next < 1577 else '0';
	vsync_reg <= '1' when count_1066_next < 1064 else '0';

	count_1688 <= count_1688_next;
	count_1066 <= count_1066_next;
	
	counterv <= count_1066;
	counterh <= count_1688;
	
	h_end <= '1' when count_1688_next = (PPL + HFP + HBP + HRE - 1) else '0';
	v_end <= '1' when count_1066_next = (LIN + VFP + VBP + VRE - 1) else '0';
	
	hfin <= h_end;
	vfin <= v_end;

end arch;