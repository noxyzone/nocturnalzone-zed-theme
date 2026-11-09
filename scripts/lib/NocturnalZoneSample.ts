// NocturnalZone — Brand Color Palette

interface ColorToken {
  name: string;
  hex: string;
  isActive: boolean;
}
type Appearance = "dark" | "light";

const PALETTE: ColorToken[] = [
  { name: "Background", hex: "#000000", isActive: true },
  { name: "Surface",    hex: "#18181D", isActive: true },
  { name: "Overlay",    hex: "#2C2C2E", isActive: true },
  { name: "Accent",     hex: "#79C0DC", isActive: true },
  { name: "Success",    hex: "#4DB890", isActive: true },
  { name: "Warning",    hex: "#F4A823", isActive: true },
  { name: "Error",      hex: "#F478A0", isActive: true },
];

function hexToRgb(hex: string): [number, number, number] {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 0xff, (n >> 8) & 0xff, n & 0xff];
}

function luminance(hex: string): number {
  const [r, g, b] = hexToRgb(hex).map((c) => {
    const s = c / 255;
    return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrastRatio(a: string, b: string): number {
  const [l1, l2] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (l1 + 0.05) / (l2 + 0.05);
}

class PaletteViewModel {
  tokens: ColorToken[];
  appearance: Appearance;

  constructor(tokens: ColorToken[], appearance: Appearance = "dark") {
    this.tokens = tokens;
    this.appearance = appearance;
  }

  toggle(name: string): void {
    const token = this.tokens.find((t) => t.name === name);
    if (token) token.isActive = !token.isActive;
  }

  get activeTokens(): ColorToken[] {
    return this.tokens.filter((t) => t.isActive);
  }

  contrastAgainstBackground(hex: string): string {
    const bg = this.tokens.find((t) => t.name === "Background")!.hex;
    return contrastRatio(hex, bg).toFixed(2);
  }
}

const vm = new PaletteViewModel(PALETTE);
console.log("NocturnalZone Palette");
for (const token of vm.activeTokens) {
  const ratio = vm.contrastAgainstBackground(token.hex);
  console.log(`  ${token.name.padEnd(12)} ${token.hex}  contrast: ${ratio}`);
}
