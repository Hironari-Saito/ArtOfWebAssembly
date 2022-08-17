export class Vector2D {
  // x: f32;
  // y: f32;
  private x: f32;
  private y: f32;

  constructor(x: f32, y: f32) {
    this.x = x;
    this.y = y;
  }

  Magnitude(): f32 {
    return Mathf.sqrt(this.x * this.x + this.y * this.y);
  }
}