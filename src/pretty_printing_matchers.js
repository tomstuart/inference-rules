export default {
  toLookLike(object, string) {
    if (object.toString() === string) {
      return {
        pass: true,
        message: `expected ${object} not to look like “${string}”`
      };
    } else {
      return {
        pass: false,
        message: `expected ${object} to look like “${string}”`
      }
    }
  }
};
