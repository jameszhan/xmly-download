function shuffle(origin, array) {
    var target = [], i, j, c;
    for (i = 0; i < origin.length; i++) {
        c = 'a' <= origin[i] && 'z' >= origin[i] ? origin[i].charCodeAt(0) - 97 : origin[i] - 0 + 26;
        for (j = 0; j < 36; j++) {
            if (array[j] === c) {
                c = j;
                break;
            }
        }
        target[i] = 25 < c ? c - 26 : String.fromCharCode(c + 97);
    }
    return target.join('');
}

function decrypt(ep, key, array) {
    var new_key = shuffle(key, array);
    console.log(new_key);
    return do_decrypt(new_key, pre_decrypt(ep));
}

function pre_decrypt(ep) {
    if (!ep) {
        return '';
    }
    var n = ep.length,
        i,
        e,
        f,
        s = '',
        table = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
            -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 52, 53, 54,
            55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
            15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34,
            35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1];

    for (i = 0; i < n;) {
        do {
            e = table[255 & ep.charCodeAt(i++)];
        } while (i < n && -1 === e);
        if (-1 === e) break;

        do {
            f = table[255 & ep.charCodeAt(i++)];
        } while (i < n && -1 === f);
        if (-1 === f) break;

        s += String.fromCharCode(e << 2 | (48 & f) >> 4);
        do {
            if (61 === (e = 255 & ep.charCodeAt(i++))) {
                return s;
            }
            e = table[e];
        } while (i < n && -1 === e);
        if (-1 === e) break;

        s += String.fromCharCode((15 & f) << 4 | (60 & e) >> 2);
        do {
            if (61 === (f = 255 & ep.charCodeAt(i++))) {
                return s;
            }
            f = table[f];
        } while (i < n && -1 === f);
        if (-1 === f) break;

        s += String.fromCharCode((3 & e) << 6 | f);
    }
    return s;
}


function do_decrypt(key, ep) {
    var str = '',
        chars = [],
        i,
        n,
        t,
        j,
        s;
    for (i = 0; i < 256; i++) {
        chars[i] = i;
    }
    for (n = 0, i = 0; i < 256; i++) {
        n = (n + chars[i] + key.charCodeAt(i % key.length)) % 256;
        t = chars[i];
        chars[i] = chars[n];
        chars[n] = t;
    }
    for (s = n = 0, j = 0; j < ep.length; j++) {
        s = (s + 1) % 256;
        n = (n + chars[s]) % 256;
        t = chars[s];
        chars[s] = chars[n];
        chars[n] = t;
        str += String.fromCharCode(ep.charCodeAt(j) ^ chars[(chars[s] + chars[n]) % 256]);
    }
    return str;
}

if (require.main === module) {
    s = "dg3utf1k6yxdwi09";
    a = [19, 1, 4, 7, 30, 14, 28, 8, 24, 17, 6, 35, 34, 16, 9, 10, 13, 22, 32, 29, 31, 21, 18, 3, 2, 23, 25, 27, 11, 20, 5, 15, 12, 0, 33, 26];
    encrypt_params = '3kFqaox2SndSj6gJPoocsAtdUxUghSLGTowfeV+0DX6qnbmF3q+Kmu9b0f6P1KJrXuV013EEeqdi0vL3wAMW3rwVOylUHb6iWNzDuDxcqRKro+RYnTkRM6gvcTKBAUOReczeQshNrmE8/fT4631Ye4C0DIkeiohLnqpn+1X8VUzh8Bk=';

    console.log(decrypt(encrypt_params, s, a));
}

