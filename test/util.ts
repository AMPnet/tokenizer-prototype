export function currentTimeWithDaysOffset(days): number {
    var result = new Date();
    result.setDate(result.getDate() + days);
    return result.getTime();
}

export function currentTimeWithSecondsOffset(seconds): number {
    var result = new Date();
    result.setSeconds(result.getSeconds() + seconds);
    return result.getTime();
}

export function mapToObject(map: Map<any, any>): object {
    const obj = {};
    map.forEach((v, k) => {
        obj[k] = v;
    });
    return obj;
}
