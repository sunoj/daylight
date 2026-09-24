function MoonPainter(canvas) {
  this.lineWidth = 2;
  this.radius = canvas.width / 2 - this.lineWidth / 2;
  this.offset = this.lineWidth / 2;

  this.canvas = canvas;
  this.ctx = canvas.getContext('2d');
}

MoonPainter.prototype = {
  _drawDisc: function () {
    this.ctx.translate(this.offset, this.offset);
    this.ctx.beginPath();
    this.ctx.arc(this.radius, this.radius, this.radius, 0, 2 * Math.PI, true);
    this.ctx.closePath();
    this.ctx.fillStyle = '#fff';
    this.ctx.strokeStyle = '#fff';
    this.ctx.lineWidth = this.lineWidth;

    this.ctx.fill();
    this.ctx.stroke();
  },

  _drawPhase: function (phase) {
    this.ctx.beginPath();
    this.ctx.arc(this.radius, this.radius, this.radius, -Math.PI / 2, Math.PI / 2, true);
    this.ctx.closePath();
    this.ctx.fillStyle = '#000';
    this.ctx.fill();

    this.ctx.translate(this.radius, this.radius);
    this.ctx.scale(phase, 1);
    this.ctx.translate(-this.radius, -this.radius);
    this.ctx.beginPath();
    this.ctx.arc(this.radius, this.radius, this.radius, -Math.PI / 2, Math.PI / 2, true);
    this.ctx.closePath();
    this.ctx.fillStyle = phase > 0 ? '#fff': '#000';
    this.ctx.fill();
  },

  /**
   * @param {Number} The phase expressed as a float in [0,1] range .
   */
  paint(phase: number) {
    this.ctx.save();
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    if (phase <= 0.5) {
      this._drawDisc();
      this._drawPhase(4 * phase - 1);
    } else {
      this.ctx.translate(this.radius + 2 * this.offset, this.radius + 2 * this.offset);
      this.ctx.rotate(Math.PI);
      this.ctx.translate(-this.radius, -this.radius);

      this._drawDisc();
      this._drawPhase(4 * (1 - phase) - 1);
    }
    this.ctx.restore();
  }
}

export default MoonPainter